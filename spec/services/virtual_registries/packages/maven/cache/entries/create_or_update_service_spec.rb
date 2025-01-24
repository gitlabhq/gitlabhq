# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VirtualRegistries::Packages::Maven::Cache::Entries::CreateOrUpdateService, :aggregate_failures, feature_category: :virtual_registry do
  let_it_be(:registry) { create(:virtual_registries_packages_maven_registry) }
  let_it_be(:project) { create(:project, namespace: registry.group) }
  let_it_be(:user) { create(:user, owner_of: project) }
  let_it_be(:path) { 'com/test/package/1.2.3/package-1.2.3.pom' }
  let_it_be(:upstream) { create(:virtual_registries_packages_maven_upstream, registry: registry) }

  let(:etag) { 'test' }
  let(:content_type) { 'text/xml' }
  let(:params) { { path: path, file: file, etag: etag, content_type: content_type } }
  let(:file) do
    UploadedFile.new(
      Tempfile.new(etag).path,
      sha1: '4e1243bd22c66e76c2ba9eddc1f91394e57f9f83',
      md5: 'd8e8fca2dc0f896fd7cb4cb0031ba249'
    )
  end

  let(:service) do
    described_class.new(upstream: upstream, current_user: user, params: params)
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    shared_examples 'returning a service response success response' do
      shared_examples 'creating a new cache entry' do |with_md5: 'd8e8fca2dc0f896fd7cb4cb0031ba249'|
        it 'returns a success service response', :freeze_time do
          expect { execute }.to change { upstream.cache_entries.count }.by(1)
          expect(execute).to be_success

          last_cache_entry = upstream.cache_entries.last
          expect(execute.payload).to eq(cache_entry: last_cache_entry)

          expect(last_cache_entry).to have_attributes(
            group_id: registry.group.id,
            upstream_checked_at: Time.zone.now,
            relative_path: "/#{path}",
            upstream_etag: etag,
            content_type: content_type,
            file_sha1: '4e1243bd22c66e76c2ba9eddc1f91394e57f9f83',
            file_md5: with_md5
          )
        end
      end

      it_behaves_like 'creating a new cache entry'

      context 'with a nil content_type' do
        let(:params) { super().merge(content_type: nil) }

        it 'creates a cache entry with a default content_type' do
          expect { execute }.to change { upstream.cache_entries.count }.by(1)
          expect(execute).to be_success

          expect(upstream.cache_entries.last).to have_attributes(content_type: 'application/octet-stream')
        end
      end

      context 'with an error' do
        it 'returns an error response and log the error' do
          expect(::VirtualRegistries::Packages::Maven::Cache::Entry)
            .to receive(:create_or_update_by!).and_raise(ActiveRecord::RecordInvalid)
          expect(::Gitlab::ErrorTracking).to receive(:track_exception)
            .with(
              instance_of(ActiveRecord::RecordInvalid),
              upstream_id: upstream.id,
              group_id: upstream.group_id,
              class: described_class.name
            )
          expect { execute }.not_to change { upstream.cache_entries.count }
        end
      end

      context 'in FIPS mode', :fips_mode do
        it_behaves_like 'creating a new cache entry', with_md5: nil
      end
    end

    context 'with a User' do
      it_behaves_like 'returning a service response success response'

      context 'with an existing cache entry' do
        let_it_be(:cache_entry) do
          create(
            :virtual_registries_packages_maven_cache_entry,
            group: upstream.group,
            upstream: upstream,
            relative_path: "/#{path}"
          )
        end

        it 'updates it', :freeze_time do
          expect { execute }.to not_change { upstream.cache_entries.count }

          expect(execute).to be_success

          last_cache_entry = upstream.cache_entries.last
          expect(execute.payload).to eq(cache_entry: last_cache_entry)

          expect(last_cache_entry).to have_attributes(
            upstream_checked_at: Time.zone.now,
            upstream_etag: etag
          )
        end
      end
    end

    context 'with a DeployToken' do
      let_it_be(:user) { create(:deploy_token, :group, groups: [registry.group], read_virtual_registry: true) }

      it_behaves_like 'returning a service response success response'
    end

    context 'with no path' do
      let(:path) { nil }

      it { is_expected.to eq(described_class::ERRORS[:path_not_present]) }
    end

    context 'with no file' do
      let(:file) { nil }

      it { is_expected.to eq(described_class::ERRORS[:file_not_present]) }
    end

    context 'with no upstream' do
      let_it_be(:upstream) { nil }

      it { is_expected.to eq(described_class::ERRORS[:unauthorized]) }
    end

    context 'with no user' do
      let(:user) { nil }

      it { is_expected.to eq(described_class::ERRORS[:unauthorized]) }
    end
  end
end
