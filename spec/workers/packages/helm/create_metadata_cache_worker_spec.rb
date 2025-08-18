# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Helm::CreateMetadataCacheWorker, feature_category: :package_registry do
  describe '#perform', :aggregate_failures do
    let_it_be(:package) { create(:helm_package) }

    let(:project) { package.project }
    let(:channel) { 'stable' }

    subject(:perform_work) { described_class.new.perform(project.id, channel) }

    shared_examples 'does nothing' do
      it 'does not trigger service to create helm metadata cache' do
        expect(::Packages::Helm::CreateMetadataCacheService).not_to receive(:new)

        perform_work
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [project.id, channel] }

      it 'creates a new metadata cache' do
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

        expect { perform_work }.to change { ::Packages::Helm::MetadataCache.count }.by(1)

        metadata_cache = ::Packages::Helm::MetadataCache.last

        expect(metadata_cache.channel).to eq(channel)
        expect(metadata_cache.project_id).to eq(project.id)
      end
    end

    context 'when errors happened' do
      it 'logs errors' do
        expect_next_instance_of(::Packages::Helm::GenerateMetadataService) do |service|
          expect(service).to receive(:execute).and_raise(StandardError)
        end

        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(
            instance_of(StandardError),
            project_id: project.id, channel: channel
          )

        perform_work
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(packages_helm_metadata_cache: false)
      end

      it_behaves_like 'does nothing'

      it 'does not query project' do
        expect(Project).not_to receive(:find_by_id)

        perform_work
      end
    end

    context 'when create service responses failed' do
      it 'logs CreationFailedError error' do
        expect_next_instance_of(::Packages::Helm::CreateMetadataCacheService) do |service|
          expect(service).to receive(:execute).and_return(
            instance_double(ServiceResponse, success?: false, message: 'error message'))
        end

        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(
            instance_of(described_class::CreationFailedError),
            project_id: project.id, channel: channel
          )

        perform_work
      end
    end

    context 'without project' do
      before do
        project.destroy!
      end

      it_behaves_like 'does nothing'
    end
  end
end
