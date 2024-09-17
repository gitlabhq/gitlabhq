# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::EntityWorker, feature_category: :importers do
  subject(:worker) { described_class.new }

  let_it_be(:entity) { create(:bulk_import_entity, :started) }

  let_it_be_with_reload(:pipeline_tracker) do
    create(
      :bulk_import_tracker,
      entity: entity,
      pipeline_name: 'Stage0::Pipeline',
      stage: 0
    )
  end

  let_it_be_with_reload(:pipeline_tracker_2) do
    create(
      :bulk_import_tracker,
      entity: entity,
      pipeline_name: 'Stage1::Pipeline',
      stage: 1
    )
  end

  include_examples 'an idempotent worker' do
    let(:job_args) { entity.id }

    before do
      allow(described_class).to receive(:perform_in)
      allow(BulkImports::PipelineWorker).to receive(:perform_async)
    end

    it 'enqueues the pipeline workers of the first stage and then re-enqueues itself' do
      expect_next_instance_of(BulkImports::Logger) do |logger|
        expect(logger).to receive(:info).with(hash_including('message' => 'Stage starting', 'entity_stage' => 0))
        expect(logger).to receive(:info).with(hash_including('message' => 'Stage running', 'entity_stage' => 0))
      end

      expect(BulkImports::PipelineWorker)
        .to receive(:perform_async)
        .with(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

      expect(described_class).to receive(:perform_in).twice.with(described_class::PERFORM_DELAY, entity.id)

      expect { subject }.to change { pipeline_tracker.reload.status_name }.from(:created).to(:enqueued)
    end
  end

  context 'when pipeline workers from a stage are running' do
    before do
      pipeline_tracker.enqueue!
    end

    it 'does not enqueue the pipeline workers from the next stage and re-enqueues itself' do
      expect_next_instance_of(BulkImports::Logger) do |logger|
        expect(logger).to receive(:info).with(hash_including('message' => 'Stage running', 'entity_stage' => 0))
      end

      expect(BulkImports::PipelineWorker).not_to receive(:perform_async)
      expect(described_class).to receive(:perform_in).with(described_class::PERFORM_DELAY, entity.id)

      worker.perform(entity.id)
    end
  end

  context 'when there are no pipeline workers from the previous stage running' do
    before do
      pipeline_tracker.fail_op!
    end

    it 'enqueues the pipeline workers from the next stage and re-enqueues itself' do
      expect_next_instance_of(BulkImports::Logger) do |logger|
        expect(logger).to receive(:with_entity).with(entity).and_call_original

        expect(logger).to receive(:info).with(hash_including('message' => 'Stage starting', 'entity_stage' => 1))
      end

      expect(BulkImports::PipelineWorker)
        .to receive(:perform_async)
          .with(
            pipeline_tracker_2.id,
            pipeline_tracker_2.stage,
            entity.id
          )

      expect(described_class).to receive(:perform_in).with(described_class::PERFORM_DELAY, entity.id)

      worker.perform(entity.id)
    end

    context 'when importer_user_mapping_enabled is enabled' do
      before do
        allow_next_instance_of(Import::BulkImports::EphemeralData) do |ephemeral_data|
          allow(ephemeral_data).to receive(:importer_user_mapping_enabled?).and_return(true)
        end
      end

      it 'enqueues Import::LoadPlaceholderReferencesWorker' do
        expect(Import::LoadPlaceholderReferencesWorker)
          .to receive(:perform_async)
          .with(
            Import::SOURCE_DIRECT_TRANSFER,
            entity.bulk_import_id,
            'current_user_id' => entity.bulk_import.user_id
          )

        subject
      end
    end

    context 'when exclusive lease cannot be obtained' do
      it 'does not start next stage and re-enqueue worker' do
        expect_next_instance_of(Gitlab::ExclusiveLease) do |lease|
          expect(lease).to receive(:try_obtain).and_return(false)
        end

        expect_next_instance_of(BulkImports::Logger) do |logger|
          expect(logger).to receive(:info).with(
            hash_including(
              'message' => 'Cannot obtain an exclusive lease. There must be another instance already in execution.'
            )
          )
        end

        expect(described_class).to receive(:perform_in)

        worker.perform(entity.id)
      end
    end
  end

  context 'when there are no next stage to run' do
    before do
      pipeline_tracker.fail_op!
      pipeline_tracker_2.fail_op!
    end

    it 'does not enqueue any pipeline worker and re-enqueues itself' do
      expect(BulkImports::PipelineWorker).not_to receive(:perform_async)
      expect(described_class).to receive(:perform_in).with(described_class::PERFORM_DELAY, entity.id)

      worker.perform(entity.id)
    end
  end

  context 'when entity status is not started' do
    let(:entity) { create(:bulk_import_entity, :finished) }

    it 'does not re-enqueues itself' do
      expect(described_class).not_to receive(:perform_in)

      worker.perform(entity.id)
    end
  end

  describe '#sidekiq_retries_exhausted' do
    it 'logs export failure and marks entity as failed' do
      exception = StandardError.new('Exhausted error!')

      expect(Gitlab::ErrorTracking)
        .to receive(:track_exception)
        .with(exception, a_hash_including(
          message: "Request to export #{entity.source_type} failed",
          bulk_import_entity_id: entity.id,
          bulk_import_id: entity.bulk_import_id,
          bulk_import_entity_type: entity.source_type,
          source_full_path: entity.source_full_path,
          source_version: entity.bulk_import.source_version_info.to_s,
          importer: 'gitlab_migration'
        ))

      described_class.sidekiq_retries_exhausted_block.call({ 'args' => [entity.id] }, exception)

      expect(entity.reload.failed?).to eq(true)
    end
  end
end
