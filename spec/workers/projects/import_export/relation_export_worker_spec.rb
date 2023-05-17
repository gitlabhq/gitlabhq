# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::RelationExportWorker, type: :worker, feature_category: :importers do
  let(:project_relation_export) { create(:project_relation_export) }
  let(:job_args) { [project_relation_export.id] }

  it_behaves_like 'an idempotent worker'

  describe '#perform' do
    subject(:worker) { described_class.new }

    context 'when relation export has initial status `queued`' do
      it 'exports the relation' do
        expect_next_instance_of(Projects::ImportExport::RelationExportService) do |service|
          expect(service).to receive(:execute)
        end

        worker.perform(project_relation_export.id)
      end
    end

    context 'when relation export has status `started`' do
      let(:project_relation_export) { create(:project_relation_export, :started) }

      it 'retries the export of the relation' do
        expect_next_instance_of(Projects::ImportExport::RelationExportService) do |service|
          expect(service).to receive(:execute)
        end

        worker.perform(project_relation_export.id)

        expect(project_relation_export.reload.queued?).to eq(true)
      end
    end

    context 'when relation export does not have status `queued` or `started`' do
      let(:project_relation_export) { create(:project_relation_export, :finished) }

      it 'does not export the relation' do
        expect(Projects::ImportExport::RelationExportService).not_to receive(:new)

        worker.perform(project_relation_export.id)
      end
    end
  end

  describe '.sidekiq_retries_exhausted' do
    let(:job) { { 'args' => [project_relation_export.id], 'error_message' => 'Error message' } }

    it 'sets relation export status to `failed`' do
      described_class.sidekiq_retries_exhausted_block.call(job)

      expect(project_relation_export.reload.failed?).to eq(true)
    end

    it 'logs the error message' do
      expect_next_instance_of(Gitlab::Export::Logger) do |logger|
        expect(logger).to receive(:error).with(
          hash_including(
            message: 'Project relation export failed',
            export_error: 'Error message'
          )
        )
      end

      described_class.sidekiq_retries_exhausted_block.call(job)
    end
  end
end
