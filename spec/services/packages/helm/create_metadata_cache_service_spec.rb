# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Helm::CreateMetadataCacheService, :clean_gitlab_redis_shared_state, feature_category: :package_registry do
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:channel) { "stable" }
  let_it_be(:package) { create(:helm_package, project: project) }
  let_it_be(:package_file) { create(:helm_package_file, package: package, channel: channel) }

  let(:lease_key) { "packages:helm:create_metadata_cache_service:metadata_caches:#{project.id}_#{channel}" }
  let(:service) { described_class.new(project, channel) }

  describe '#execute' do
    let(:new_metadata_cache) { Packages::Helm::MetadataCache.last }

    subject(:execute) { service.execute }

    it 'returns success response' do
      expect(execute).to be_success
    end

    it 'invokes generate metadata service' do
      expect(Packages::Helm::GenerateMetadataService).to receive(:new).with(
        project.id,
        channel,
        [package]
      ).and_call_original

      execute
    end

    it 'contains correct keys in metadata content' do
      execute

      metadata_content = YAML.load(new_metadata_cache.file.read)
      expect(metadata_content.keys).to contain_exactly('apiVersion', 'entries', 'generated', 'serverInfo')
    end

    it 'finds packages with no recent limit' do
      expect(Packages::Helm::PackagesFinder).to receive(:new).with(
        project, channel, with_recent_limit: false
      ).and_call_original

      execute
    end

    it 'obtains a lease to create a new metadata cache' do
      expect_to_obtain_exclusive_lease(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)

      execute
    end

    shared_examples 'update failed' do
      context 'when update! failed' do
        before do
          allow(CarrierWaveStringFile).to receive(:new).and_return(nil)
        end

        it 'returns ServiceResponse.error' do
          response = execute

          expect(response.message).to eq("Validation failed: File can't be blank")
        end
      end
    end

    context 'with no existing metadata cache' do
      it 'creates a new metadata cache', :aggregate_failures do
        expect { execute }.to change { Packages::Helm::MetadataCache.count }.by(1)

        expect(new_metadata_cache.size).to eq(new_metadata_cache.file.read.bytesize)
        expect(new_metadata_cache.channel).to eq(channel)
        expect(new_metadata_cache.project_id).to eq(project.id)
      end

      it_behaves_like 'update failed'
    end

    context 'with existing metadata cache' do
      let_it_be(:helm_metadata_cache) { create(:helm_metadata_cache, project_id: project.id, channel: channel) }
      let_it_be(:metadata_size) { helm_metadata_cache.size }

      it 'does not create a new metadata cache' do
        expect { execute }.to not_change { Packages::Helm::MetadataCache.count }
      end

      it 'updates the metadata cache', :aggregate_failures do
        old_generated = YAML.load(helm_metadata_cache.file.read)['generated']

        execute

        helm_metadata_cache.reload
        new_generated = YAML.load(helm_metadata_cache.file.read)['generated']

        expect(new_generated).not_to eq(old_generated)
      end

      it_behaves_like 'update failed'
    end

    context 'when the lease is already taken' do
      before do
        stub_exclusive_lease_taken(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)
      end

      it 'does not create a new metadata cache' do
        expect { execute }.to not_change { Packages::Helm::MetadataCache.count }
      end

      it 'returns success response' do
        expect(execute).to be_success
      end
    end
  end

  describe '#lease_key' do
    it 'returns an unique key' do
      expect(service.send(:lease_key)).to eq lease_key
    end
  end
end
