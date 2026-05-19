# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Imports::ScheduleImportWorker, feature_category: :importers do
  let(:entities) do
    [{ source_type: 'group_entity', source_full_path: 'my-group', destination_slug: 'my-group',
       destination_namespace: '' }]
  end

  describe '#perform' do
    context 'when bulk_import does not exist' do
      it 'returns early without calling the service' do
        expect(Import::Offline::Imports::ScheduleImportService).not_to receive(:new)

        expect { described_class.new.perform(non_existing_record_id, entities) }.not_to raise_error
      end

      it 'logs a warning' do
        expect(Import::Framework::Logger).to receive(:warn).with(
          class_name: described_class.name,
          bulk_import_id: non_existing_record_id,
          message: 'BulkImport not found'
        )

        described_class.new.perform(non_existing_record_id, entities)
      end
    end

    context 'when bulk_import exists but is not in created state' do
      let(:bulk_import) { create(:bulk_import, :started) }

      it 'returns early without calling the service' do
        expect(Import::Offline::Imports::ScheduleImportService).not_to receive(:new)

        expect { described_class.new.perform(bulk_import.id, entities) }.not_to raise_error
      end

      it 'logs a warning' do
        expect(Import::Framework::Logger).to receive(:warn).with(
          class_name: described_class.name,
          bulk_import_id: bulk_import.id,
          message: 'BulkImport is not in created state'
        )

        described_class.new.perform(bulk_import.id, entities)
      end

      it 'does not mark the bulk_import as failed' do
        described_class.new.perform(bulk_import.id, entities)

        expect(bulk_import.reload.failed?).to be(false)
      end
    end

    context 'when bulk_import exists but has no offline_configuration' do
      let(:bulk_import) { create(:bulk_import) }

      it 'returns early without calling the service' do
        expect(Import::Offline::Imports::ScheduleImportService).not_to receive(:new)

        expect { described_class.new.perform(bulk_import.id, entities) }.not_to raise_error
      end

      it 'logs a warning' do
        expect(Import::Framework::Logger).to receive(:warn).with(
          class_name: described_class.name,
          bulk_import_id: bulk_import.id,
          message: 'Offline configuration not found'
        )

        described_class.new.perform(bulk_import.id, entities)
      end

      it 'marks the bulk_import as failed' do
        described_class.new.perform(bulk_import.id, entities)

        expect(bulk_import.reload.failed?).to be(true)
      end
    end

    context 'when bulk_import exists with an offline_configuration' do
      let(:bulk_import) { create(:bulk_import, :with_offline_configuration) }
      let(:job_args) { [bulk_import.id, entities] }
      let(:service) { instance_double(Import::Offline::Imports::ScheduleImportService, execute: ServiceResponse.success) }

      before do
        allow(Import::Offline::Imports::ScheduleImportService).to receive(:new).and_return(service)
      end

      it_behaves_like 'an idempotent worker'

      it 'calls ScheduleImportService with the bulk_import and entities' do
        expect(Import::Offline::Imports::ScheduleImportService).to receive(:new)
          .with(bulk_import, entities).and_return(service)
        expect(service).to receive(:execute)

        described_class.new.perform(bulk_import.id, entities)
      end
    end
  end

  describe '#sidekiq_retries_exhausted' do
    context 'when bulk_import exists' do
      let(:bulk_import) { create(:bulk_import, :with_offline_configuration) }

      it 'marks the bulk_import as failed' do
        described_class.sidekiq_retries_exhausted_block.call({ 'args' => [bulk_import.id] }, StandardError.new)

        expect(bulk_import.reload.failed?).to be(true)
      end
    end

    context 'when bulk_import does not exist' do
      it 'does nothing' do
        expect do
          described_class.sidekiq_retries_exhausted_block.call({ 'args' => [non_existing_record_id] },
            StandardError.new)
        end.not_to raise_error
      end
    end
  end
end
