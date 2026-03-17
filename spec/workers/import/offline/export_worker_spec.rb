# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::ExportWorker, feature_category: :importers do
  let_it_be_with_reload(:offline_export) { create(:offline_export) }
  let(:job_args) { [offline_export.id] }

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      context 'when offline export exists' do
        it 'calls the process service' do
          process_service = instance_double(Import::Offline::Exports::ProcessService)

          expect(Import::Offline::Exports::ProcessService).to receive(:new)
            .with(offline_export).twice.and_return(process_service)
          expect(process_service).to receive(:execute).twice

          perform_multiple(job_args)
        end
      end

      context 'when offline export does not exist' do
        let(:job_args) { [non_existing_record_id] }

        it 'returns early without raising an error' do
          expect(Import::Offline::Exports::ProcessService).not_to receive(:new)

          expect { perform_multiple(job_args) }.not_to raise_error
        end
      end
    end
  end

  describe '#sidekiq_retries_exhausted' do
    let(:exception) { StandardError.new('Export failed') }

    it 'logs export failure and marks entity as failed' do
      exception = StandardError.new('Exhausted error!')

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(exception, offline_export_id: offline_export.id)

      described_class.sidekiq_retries_exhausted_block.call({ 'args' => job_args }, exception)

      expect(offline_export.reload.failed?).to be(true)
    end

    context 'when offline export does not exist' do
      let(:job_args) { [non_existing_record_id] }

      it 'logs a warning and returns early' do
        expect(Sidekiq.logger).to receive(:warn).with(
          class: 'Import::Offline::ExportWorker',
          offline_export_id: non_existing_record_id,
          message: 'Offline export not found'
        )
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        described_class.sidekiq_retries_exhausted_block.call({ 'args' => job_args }, exception)
      end
    end
  end
end
