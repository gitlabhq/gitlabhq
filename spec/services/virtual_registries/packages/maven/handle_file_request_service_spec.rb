# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VirtualRegistries::Packages::Maven::HandleFileRequestService, :aggregate_failures, :clean_gitlab_redis_shared_state, feature_category: :virtual_registry do
  let_it_be(:registry) { create(:virtual_registries_packages_maven_registry, :with_upstream) }
  let_it_be(:project) { create(:project, namespace: registry.group) }
  let_it_be(:user) { create(:user, owner_of: project) }
  let_it_be(:path) { 'com/test/package/1.2.3/package-1.2.3.pom' }

  let(:upstream) { registry.upstream }
  let(:upstream_resource_url) { upstream.url_for(path) }
  let(:etag_returned_by_upstream) { nil }
  let(:service) { described_class.new(registry: registry, current_user: user, params: { path: path }) }

  describe '#execute' do
    subject(:execute) { service.execute }

    shared_examples 'returning a service response success response' do |action:|
      before do
        stub_external_registry_request(etag: etag_returned_by_upstream)
      end

      it 'returns a success service response' do
        expect(service).to receive(:can?).and_call_original
        expect(execute).to be_success

        expect(execute.payload[:action]).to eq(action)
        case action
        when :workhorse_upload_url
          expect(execute.payload[:action_params]).to eq(url: upstream_resource_url, upstream: upstream)
        when :download_file
          action_params = execute.payload[:action_params]
          expect(action_params[:file]).to be_instance_of(VirtualRegistries::Cache::EntryUploader)
          expect(action_params[:content_type]).to eq(cache_entry.content_type)
          expect(action_params[:file_sha1]).to be_instance_of(String)
          expect(action_params[:file_md5]).to be_instance_of(String)
        when :download_digest
          expect(execute.payload[:action_params]).to eq(digest: expected_digest)
        else
          {}
        end
      end
    end

    context 'with a User' do
      let_it_be(:processing_cache_entry) do
        create(
          :virtual_registries_packages_maven_cache_entry,
          :upstream_checked,
          :processing,
          upstream: registry.upstream,
          relative_path: "/#{path}"
        )
      end

      context 'with no cache entry' do
        it_behaves_like 'returning a service response success response', action: :workhorse_upload_url

        context 'with upstream returning an error' do
          before do
            stub_external_registry_request(status: 404)
          end

          it { is_expected.to eq(described_class::ERRORS[:file_not_found_on_upstreams]) }
        end

        context 'with upstream head raising an error' do
          before do
            stub_external_registry_request(raise_error: true)
          end

          it { is_expected.to eq(described_class::ERRORS[:upstream_not_available]) }
        end
      end

      context 'with a cache entry' do
        let_it_be_with_refind(:cache_entry) do
          create(:virtual_registries_packages_maven_cache_entry,
            :upstream_checked,
            upstream: registry.upstream,
            relative_path: "/#{path}"
          )
        end

        it_behaves_like 'returning a service response success response', action: :download_file

        context 'and is too old' do
          before do
            cache_entry.update!(upstream_checked_at: 1.year.ago)
          end

          context 'with the same etag as upstream' do
            let(:etag_returned_by_upstream) { cache_entry.upstream_etag }

            it_behaves_like 'returning a service response success response', action: :download_file

            it 'bumps the statistics', :freeze_time do
              stub_external_registry_request(etag: etag_returned_by_upstream)

              expect { execute }.to change { cache_entry.reload.upstream_checked_at }.to(Time.zone.now)
            end
          end

          context 'with a different etag as upstream' do
            let(:etag_returned_by_upstream) { "#{cache_entry.upstream_etag}_test" }

            it_behaves_like 'returning a service response success response', action: :workhorse_upload_url
          end

          context 'with a stored blank etag' do
            before do
              cache_entry.update!(upstream_etag: nil)
            end

            it_behaves_like 'returning a service response success response', action: :workhorse_upload_url
          end
        end

        context 'when accessing the sha1 digest' do
          let(:path) { "#{super()}.sha1" }
          let(:expected_digest) { cache_entry.file_sha1 }

          it_behaves_like 'returning a service response success response', action: :download_digest

          context 'when the cache entry does not exist' do
            let(:path) { "#{super()}_not_existing.sha1" }

            it { is_expected.to eq(described_class::ERRORS[:digest_not_found]) }
          end
        end

        context 'when accessing the md5 digest' do
          let(:path) { "#{super()}.md5" }
          let(:expected_digest) { cache_entry.file_md5 }

          it_behaves_like 'returning a service response success response', action: :download_digest

          context 'when the cache entry does not exist' do
            let(:path) { "#{super()}_not_existing.md5" }

            it { is_expected.to eq(described_class::ERRORS[:digest_not_found]) }
          end

          context 'in FIPS mode', :fips_mode do
            it { is_expected.to eq(described_class::ERRORS[:fips_unsupported_md5]) }
          end
        end

        context 'with upstream head raising an error' do
          before do
            stub_external_registry_request(raise_error: true)
          end

          it_behaves_like 'returning a service response success response', action: :download_file
        end

        context 'with a cached permissions evaluation' do
          before do
            Rails.cache.fetch(service.send(:permissions_cache_key)) do
              can?(user, :read_virtual_registry, registry)
            end
          end

          it 'does not call the permissions evaluation again' do
            expect(service).not_to receive(:can).and_call_original
            expect(execute).to be_success
          end
        end
      end
    end

    context 'with a DeployToken' do
      let_it_be(:user) { create(:deploy_token, :group, groups: [registry.group], read_virtual_registry: true) }

      it_behaves_like 'returning a service response success response', action: :workhorse_upload_url
    end

    context 'with no path' do
      let(:path) { nil }

      it { is_expected.to eq(described_class::ERRORS[:path_not_present]) }
    end

    context 'with no user' do
      let(:user) { nil }

      it { is_expected.to eq(described_class::ERRORS[:unauthorized]) }
    end

    context 'with registry with no upstreams' do
      before do
        registry.upstream = nil
      end

      it { is_expected.to eq(described_class::ERRORS[:no_upstreams]) }
    end

    def stub_external_registry_request(status: 200, raise_error: false, etag: nil)
      request = stub_request(:head, upstream_resource_url)
        .with(headers: upstream.headers)

      if raise_error
        request.to_raise(Gitlab::HTTP::BlockedUrlError)
      else
        request.to_return(status: status, body: '', headers: { 'etag' => etag }.compact)
      end
    end
  end
end
