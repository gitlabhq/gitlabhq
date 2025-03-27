# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::ProcessPackageFileWorker, type: :worker, feature_category: :package_registry do
  let_it_be(:package_file) { create(:conan_package_file, :conan_package_info) }

  let(:worker) { described_class.new }
  let(:package_file_id) { package_file.id }

  describe "#perform" do
    subject(:perform) { worker.perform(package_file_id) }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { package_file_id }
    end

    it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

    it 'has :until_executed deduplicate strategy' do
      expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
    end

    context 'with existing package file' do
      it 'calls the MetadataExtractionService' do
        expect_next_instance_of(::Packages::Conan::MetadataExtractionService, package_file) do |service|
          expect(service).to receive(:execute)
        end

        perform
      end

      context 'when service raises an error' do
        let(:exception) { ::Packages::Conan::MetadataExtractionService::ExtractionError.new('test error') }

        before do
          allow_next_instance_of(::Packages::Conan::MetadataExtractionService) do |service|
            allow(service).to receive(:execute).and_raise(exception)
          end
        end

        it 'processes the error through error handling concern' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
            exception,
            package_file_id: package_file.id,
            project_id: package_file.project_id,
            package_name: package_file.package.name,
            package_version: package_file.package.version
          )

          perform
        end
      end
    end

    context 'with a non-existing package file' do
      let(:package_file_id) { non_existing_record_id }

      it 'does not call the service' do
        expect(::Packages::Conan::MetadataExtractionService).not_to receive(:new)

        perform
      end
    end
  end
end
