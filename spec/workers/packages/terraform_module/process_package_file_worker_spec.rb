# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::TerraformModule::ProcessPackageFileWorker, type: :worker, feature_category: :package_registry do
  let_it_be(:package_file) { create(:package_file, :terraform_module) }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [package_file.id] }
  end

  describe '#perform' do
    subject(:perform_work) { described_class.new.perform(package_file.id) }

    it 'calls the service' do
      expect_next_instance_of(Packages::TerraformModule::ProcessPackageFileService, package_file) do |service|
        expect(service).to receive(:execute)
      end

      perform_work
    end

    context 'when the package file does not exist' do
      let(:package_file) { instance_double(Packages::PackageFile, id: non_existing_record_id) }

      it 'does not call the service' do
        expect(Packages::TerraformModule::ProcessPackageFileService).not_to receive(:new)

        perform_work
      end
    end

    context 'when the service raises an error' do
      it 'tracks the exception' do
        allow_next_instance_of(Packages::TerraformModule::ProcessPackageFileService) do |service|
          allow(service).to receive(:execute).and_raise(StandardError)
        end

        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          an_instance_of(StandardError),
          package_id: package_file.package_id
        )

        perform_work
      end
    end
  end
end
