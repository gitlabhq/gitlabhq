# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::EntityWorker, feature_category: :importers do
  let_it_be(:entity) { create(:bulk_import_entity) }

  let_it_be(:pipeline_tracker) do
    create(
      :bulk_import_tracker,
      entity: entity,
      pipeline_name: 'Stage0::Pipeline',
      stage: 0
    )
  end

  let(:job_args) { entity.id }

  it 'updates pipeline trackers to enqueued state when selected' do
    worker = BulkImports::EntityWorker.new

    next_tracker = worker.send(:next_pipeline_trackers_for, entity.id).first

    next_tracker.reload

    expect(next_tracker.enqueued?).to be_truthy

    expect(worker.send(:next_pipeline_trackers_for, entity.id))
      .not_to include(next_tracker)
  end

  include_examples 'an idempotent worker' do
    it 'enqueues the first stage pipelines work' do
      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        # the worker runs twice but only executes once
        expect(logger)
          .to receive(:info).twice
          .with(
            hash_including(
              'bulk_import_entity_id' => entity.id,
              'bulk_import_id' => entity.bulk_import_id,
              'bulk_import_entity_type' => entity.source_type,
              'source_full_path' => entity.source_full_path,
              'current_stage' => nil,
              'message' => 'Stage starting',
              'source_version' => entity.bulk_import.source_version_info.to_s,
              'importer' => 'gitlab_migration'
            )
          )
      end

      expect(BulkImports::PipelineWorker)
        .to receive(:perform_async)
        .with(
          pipeline_tracker.id,
          pipeline_tracker.stage,
          entity.id
        )

      subject
    end

    it 'logs and tracks the raised exceptions' do
      exception = StandardError.new('Error!')

      expect(BulkImports::PipelineWorker)
        .to receive(:perform_async)
        .and_raise(exception)

      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger)
          .to receive(:info).twice
          .with(
            hash_including(
              'bulk_import_entity_id' => entity.id,
              'bulk_import_id' => entity.bulk_import_id,
              'bulk_import_entity_type' => entity.source_type,
              'source_full_path' => entity.source_full_path,
              'current_stage' => nil,
              'source_version' => entity.bulk_import.source_version_info.to_s,
              'importer' => 'gitlab_migration'
            )
          )

        expect(logger)
          .to receive(:error)
          .with(
            hash_including(
              'bulk_import_entity_id' => entity.id,
              'bulk_import_id' => entity.bulk_import_id,
              'bulk_import_entity_type' => entity.source_type,
              'source_full_path' => entity.source_full_path,
              'current_stage' => nil,
              'message' => 'Entity failed',
              'exception.backtrace' => anything,
              'exception.class' => 'StandardError',
              'exception.message' => 'Error!',
              'importer' => 'gitlab_migration',
              'source_version' => entity.bulk_import.source_version_info.to_s
            )
          )
      end

      expect(Gitlab::ErrorTracking)
        .to receive(:track_exception)
              .with(
                exception,
                bulk_import_entity_id: entity.id,
                bulk_import_id: entity.bulk_import_id,
                bulk_import_entity_type: entity.source_type,
                source_full_path: entity.source_full_path,
                source_version: entity.bulk_import.source_version_info.to_s,
                importer: 'gitlab_migration'
              )

      subject

      expect(entity.reload.failed?).to eq(true)
    end

    context 'in first stage' do
      let(:job_args) { [entity.id, 0] }

      it 'do not enqueue a new pipeline job if the current stage still running' do
        expect_next_instance_of(Gitlab::Import::Logger) do |logger|
          expect(logger)
            .to receive(:info).twice
            .with(
              hash_including(
                'bulk_import_entity_id' => entity.id,
                'bulk_import_id' => entity.bulk_import_id,
                'bulk_import_entity_type' => entity.source_type,
                'source_full_path' => entity.source_full_path,
                'current_stage' => 0,
                'message' => 'Stage running',
                'source_version' => entity.bulk_import.source_version_info.to_s,
                'importer' => 'gitlab_migration'
              )
            )
        end

        expect(BulkImports::PipelineWorker)
          .not_to receive(:perform_async)

        subject
      end

      it 'enqueues the next stage pipelines when the current stage is finished' do
        next_stage_pipeline_tracker = create(
          :bulk_import_tracker,
          entity: entity,
          pipeline_name: 'Stage1::Pipeline',
          stage: 1
        )

        pipeline_tracker.fail_op!

        expect_next_instance_of(Gitlab::Import::Logger) do |logger|
          expect(logger)
            .to receive(:info).twice
            .with(
              hash_including(
                'bulk_import_entity_id' => entity.id,
                'bulk_import_id' => entity.bulk_import_id,
                'bulk_import_entity_type' => entity.source_type,
                'source_full_path' => entity.source_full_path,
                'current_stage' => 0,
                'source_version' => entity.bulk_import.source_version_info.to_s,
                'importer' => 'gitlab_migration'
              )
            )
        end

        expect(BulkImports::PipelineWorker)
          .to receive(:perform_async)
            .with(
              next_stage_pipeline_tracker.id,
              next_stage_pipeline_tracker.stage,
              entity.id
            )

        subject
      end
    end
  end
end
