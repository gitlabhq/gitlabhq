# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::CreateMetadataCacheWorker, type: :worker, feature_category: :package_registry do
  describe '#perform', :aggregate_failures do
    let_it_be(:package) { create(:npm_package) }

    let(:project) { package.project }
    let(:package_name) { package.name }

    subject { described_class.new.perform(project.id, package_name) }

    shared_examples 'does not trigger service to create npm metadata cache' do
      it do
        expect(::Packages::Npm::CreateMetadataCacheService).not_to receive(:new)

        subject
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [project.id, package_name] }

      it 'creates a new metadata cache' do
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

        expect { subject }.to change { ::Packages::Npm::MetadataCache.count }.by(1)

        metadata_cache = ::Packages::Npm::MetadataCache.last

        expect(metadata_cache.package_name).to eq(package_name)
        expect(metadata_cache.project_id).to eq(project.id)
      end
    end

    context 'when errors happened' do
      it 'logs errors' do
        expect_next_instance_of(::Packages::Npm::GenerateMetadataService) do |service|
          expect(service).to receive(:execute).and_raise(StandardError)
        end

        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(
            instance_of(StandardError),
            project_id: project.id,
            package_name: package_name
          )

        subject
      end
    end

    context 'without project' do
      before do
        project.destroy!
      end

      it_behaves_like 'does not trigger service to create npm metadata cache'
    end
  end
end
