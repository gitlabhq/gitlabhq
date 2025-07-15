# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::RelationExportWorker, type: :worker, feature_category: :importers do
  let(:project_relation_export) { create(:project_relation_export) }
  let(:user) { create(:user) }
  let(:job_args) { [project_relation_export.id, user.id] }

  it_behaves_like 'an idempotent worker'

  shared_examples 'marks relation export failed' do
    let(:error_message) { 'Error message' }
    let(:exception) { nil }

    it 'does not call service, sets relation export status to `failed`, and logs error (exception too if present)' do
      expect(Projects::ImportExport::RelationExportService).not_to receive(:new)

      expect_next_instance_of(Gitlab::Export::Logger) do |logger|
        expect(logger).to receive(:error).with(
          hash_including(
            message: 'Project relation export failed',
            export_error: error_message
          )
        )
      end

      if exception.present?
        expect_next_instance_of(Gitlab::ExceptionLogFormatter) do |formatter|
          expect(formatter).to receive(:format!).with(
            exception,
            hash_including(
              message: 'Project relation export failed',
              export_error: error_message
            )
          )
        end
      end

      worker

      expect(project_relation_export.reload.failed?).to eq(true)
    end
  end

  describe '#perform' do
    subject(:worker) { described_class.new.perform(*job_args) }

    context 'when relation export has initial status `queued`' do
      it 'exports the relation' do
        expect_next_instance_of(Projects::ImportExport::RelationExportService) do |service|
          expect(service).to receive(:execute)
        end

        worker
      end
    end

    context 'when relation export has status `started`' do
      let(:project_relation_export) { create(:project_relation_export, :started) }

      it 'retries the export of the relation' do
        expect_next_instance_of(Projects::ImportExport::RelationExportService) do |service|
          expect(service).to receive(:execute)
        end

        worker

        expect(project_relation_export.reload.queued?).to eq(true)
      end
    end

    context 'when relation export does not have status `queued` or `started`' do
      let(:project_relation_export) { create(:project_relation_export, :finished) }

      it 'does not export the relation' do
        expect(Projects::ImportExport::RelationExportService).not_to receive(:new)

        worker
      end
    end

    context 'when importing user is banned' do
      let(:user) { create(:user, :banned) }

      it_behaves_like 'marks relation export failed' do
        let(:error_message) { "User #{user.id} is banned" }
      end
    end
  end

  describe '.sidekiq_retries_exhausted' do
    let(:job) { { 'args' => job_args, 'error_message' => 'Sidekiq error message' } }
    let(:exception) { StandardError.new('Sidekiq error occurred') }

    subject(:worker) { described_class.sidekiq_retries_exhausted_block.call(job) }

    it_behaves_like 'marks relation export failed' do
      let(:error_message) { 'Sidekiq error message' }
    end
  end
end
