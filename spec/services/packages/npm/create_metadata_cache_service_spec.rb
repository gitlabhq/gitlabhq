# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::CreateMetadataCacheService, :clean_gitlab_redis_shared_state, feature_category: :package_registry do
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:package_name) { "@#{project.root_namespace.path}/npm-test" }
  let_it_be(:package) { create(:npm_package, version: '1.0.0', project: project, name: package_name) }

  let(:lease_key) { "packages:npm:create_metadata_cache_service:metadata_caches:#{project.id}_#{package_name}" }
  let(:service) { described_class.new(project, package_name) }

  describe '#execute' do
    let(:npm_metadata_cache) { Packages::Npm::MetadataCache.last }

    subject { service.execute }

    it 'creates a new metadata cache', :aggregate_failures do
      expect { subject }.to change { Packages::Npm::MetadataCache.count }.by(1)

      metadata = Gitlab::Json.parse(npm_metadata_cache.file.read)

      expect(npm_metadata_cache.package_name).to eq(package_name)
      expect(npm_metadata_cache.project_id).to eq(project.id)
      expect(npm_metadata_cache.size).to eq(metadata.to_json.bytesize)
      expect(metadata['name']).to eq(package_name)
      expect(metadata['versions'].keys).to contain_exactly('1.0.0')
    end

    context 'with existing metadata cache' do
      let_it_be(:npm_metadata_cache) { create(:npm_metadata_cache, package_name: package_name, project_id: project.id) }
      let_it_be(:metadata) { Gitlab::Json.parse(npm_metadata_cache.file.read) }
      let_it_be(:metadata_size) { npm_metadata_cache.size }
      let_it_be(:tag_name) { 'new-tag' }
      let_it_be(:tag) { create(:packages_tag, package: package, name: tag_name) }

      it 'does not create a new metadata cache' do
        expect { subject }.to change { Packages::Npm::MetadataCache.count }.by(0)
      end

      it 'updates the metadata cache', :aggregate_failures do
        subject

        new_metadata = Gitlab::Json.parse(npm_metadata_cache.file.read)

        expect(new_metadata).not_to eq(metadata)
        expect(new_metadata['dist-tags'].keys).to include(tag_name)
        expect(npm_metadata_cache.reload.size).not_to eq(metadata_size)
      end
    end

    it 'obtains a lease to create a new metadata cache' do
      expect_to_obtain_exclusive_lease(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)

      subject
    end

    context 'when the lease is already taken' do
      before do
        stub_exclusive_lease_taken(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)
      end

      it 'does not create a new metadata cache' do
        expect { subject }.to change { Packages::Npm::MetadataCache.count }.by(0)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#lease_key' do
    subject { service.send(:lease_key) }

    it 'returns an unique key' do
      is_expected.to eq lease_key
    end
  end
end
