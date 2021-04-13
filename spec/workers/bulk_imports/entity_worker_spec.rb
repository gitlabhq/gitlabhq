# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::EntityWorker do
  let_it_be(:entity) { create(:bulk_import_entity) }

  let_it_be(:pipeline_tracker) do
    create(
      :bulk_import_tracker,
      entity: entity,
      pipeline_name: 'Stage0::Pipeline',
      stage: 0
    )
  end

  it 'enqueues the first stage pipelines work' do
    expect_next_instance_of(Gitlab::Import::Logger) do |logger|
      expect(logger)
        .to receive(:info)
        .with(
          worker: described_class.name,
          entity_id: entity.id,
          current_stage: nil
        )
    end

    expect(BulkImports::PipelineWorker)
      .to receive(:perform_async)
      .with(
        pipeline_tracker.id,
        pipeline_tracker.stage,
        entity.id
      )

    subject.perform(entity.id)
  end

  it 'do not enqueue a new pipeline job if the current stage still running' do
    expect(BulkImports::PipelineWorker)
      .not_to receive(:perform_async)

    subject.perform(entity.id, 0)
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
        .to receive(:info)
        .with(
          worker: described_class.name,
          entity_id: entity.id,
          current_stage: 0
        )
    end

    expect(BulkImports::PipelineWorker)
      .to receive(:perform_async)
      .with(
        next_stage_pipeline_tracker.id,
        next_stage_pipeline_tracker.stage,
        entity.id
      )

    subject.perform(entity.id, 0)
  end

  it 'logs and tracks the raised exceptions' do
    exception = StandardError.new('Error!')

    expect(BulkImports::PipelineWorker)
      .to receive(:perform_async)
      .and_raise(exception)

    expect_next_instance_of(Gitlab::Import::Logger) do |logger|
      expect(logger)
        .to receive(:info)
        .with(
          worker: described_class.name,
          entity_id: entity.id,
          current_stage: nil
        )

      expect(logger)
        .to receive(:error)
        .with(
          worker: described_class.name,
          entity_id: entity.id,
          current_stage: nil,
          error_message: 'Error!'
        )
    end

    expect(Gitlab::ErrorTracking)
      .to receive(:track_exception)
      .with(exception, entity_id: entity.id)

    subject.perform(entity.id)
  end
end
