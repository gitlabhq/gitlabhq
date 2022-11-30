# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::ParallelProjectExportWorker, feature_category: :importers do
  let_it_be(:user) { create(:user) }

  let(:export_job) { create(:project_export_job, :started) }
  let(:after_export_strategy) { {} }
  let(:job_args) { [export_job.id, user.id, after_export_strategy] }

  before do
    allow_next_instance_of(described_class) do |job|
      allow(job).to receive(:jid) { SecureRandom.hex(8) }
    end
  end

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      it 'sets the export job status to finished' do
        subject

        expect(export_job.reload.finished?).to eq(true)
      end
    end

    context 'when after export strategy does not exist' do
      let(:after_export_strategy) { { 'klass' => 'InvalidStrategy' } }

      it 'sets the export job status to failed' do
        described_class.new.perform(*job_args)

        expect(export_job.reload.failed?).to eq(true)
      end
    end
  end

  describe '.sidekiq_retries_exhausted' do
    let(:job) { { 'args' => job_args, 'error_message' => 'Error message' } }

    it 'sets export_job status to failed' do
      described_class.sidekiq_retries_exhausted_block.call(job)

      expect(export_job.reload.failed?).to eq(true)
    end

    it 'logs an error message' do
      expect_next_instance_of(Gitlab::Export::Logger) do |logger|
        expect(logger).to receive(:error).with(
          hash_including(
            message: 'Parallel project export error',
            export_error: 'Error message'
          )
        )
      end

      described_class.sidekiq_retries_exhausted_block.call(job)
    end
  end
end
