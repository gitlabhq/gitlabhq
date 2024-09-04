# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VirtualRegistries::Packages::Maven::CachedResponses::CreateService, :aggregate_failures, feature_category: :virtual_registry do
  let_it_be(:registry) { create(:virtual_registries_packages_maven_registry) }
  let_it_be(:project) { create(:project, namespace: registry.group) }
  let_it_be(:user) { create(:user, owner_of: project) }
  let_it_be(:upstream) { create(:virtual_registries_packages_maven_upstream, registry: registry) }

  let(:path) { 'com/test/package/1.2.3/package-1.2.3.pom' }
  let(:etag) { 'test' }
  let(:file) { UploadedFile.new(Tempfile.new(etag).path) }

  let(:service) do
    described_class.new(upstream: upstream, current_user: user, params: { path: path, file: file, etag: etag })
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    shared_examples 'returning a service response success response' do
      it 'returns a success service response', :freeze_time do
        expect { execute }.to change { upstream.cached_responses.count }.by(1)
        expect(execute).to be_success

        last_cached_response = upstream.cached_responses.last
        expect(execute.payload).to eq(cached_response: last_cached_response)

        expect(last_cached_response).to have_attributes(
          group_id: registry.group.id,
          upstream_checked_at: Time.zone.now,
          downloaded_at: Time.zone.now,
          downloads_count: 1,
          relative_path: "/#{path}",
          upstream_etag: etag
        )
      end
    end

    context 'with a User' do
      it_behaves_like 'returning a service response success response'
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
