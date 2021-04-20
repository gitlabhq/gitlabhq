# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::PipelineWorker do
  let(:pipeline_class) do
    Class.new do
      def initialize(_); end

      def run; end
    end
  end

  let_it_be(:entity) { create(:bulk_import_entity) }

  before do
    stub_const('FakePipeline', pipeline_class)
  end

  it 'runs the given pipeline successfully' do
    pipeline_tracker = create(
      :bulk_import_tracker,
      entity: entity,
      pipeline_name: 'FakePipeline'
    )

    expect(BulkImports::Stage)
      .to receive(:pipeline_exists?)
      .with('FakePipeline')
      .and_return(true)

    expect_next_instance_of(Gitlab::Import::Logger) do |logger|
      expect(logger)
        .to receive(:info)
        .with(
          worker: described_class.name,
          pipeline_name: 'FakePipeline',
          entity_id: entity.id
        )
    end

    expect(BulkImports::EntityWorker)
      .to receive(:perform_async)
      .with(entity.id, pipeline_tracker.stage)

    expect(subject).to receive(:jid).and_return('jid')

    subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

    pipeline_tracker.reload

    expect(pipeline_tracker.status_name).to eq(:finished)
    expect(pipeline_tracker.jid).to eq('jid')
  end

  context 'when the pipeline cannot be found' do
    it 'logs the error' do
      pipeline_tracker = create(
        :bulk_import_tracker,
        :started,
        entity: entity,
        pipeline_name: 'FakePipeline'
      )

      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger)
          .to receive(:error)
          .with(
            worker: described_class.name,
            pipeline_tracker_id: pipeline_tracker.id,
            entity_id: entity.id,
            message: 'Unstarted pipeline not found'
          )
      end

      expect(BulkImports::EntityWorker)
        .to receive(:perform_async)
        .with(entity.id, pipeline_tracker.stage)

      subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)
    end
  end

  context 'when the pipeline raises an exception' do
    it 'logs the error' do
      pipeline_tracker = create(
        :bulk_import_tracker,
        entity: entity,
        pipeline_name: 'InexistentPipeline'
      )

      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger)
          .to receive(:error)
          .with(
            worker: described_class.name,
            pipeline_name: 'InexistentPipeline',
            entity_id: entity.id,
            message: "'InexistentPipeline' is not a valid BulkImport Pipeline"
          )
      end

      expect(Gitlab::ErrorTracking)
        .to receive(:track_exception)
        .with(
          instance_of(NameError),
          entity_id: entity.id,
          pipeline_name: pipeline_tracker.pipeline_name
        )

      expect(BulkImports::EntityWorker)
        .to receive(:perform_async)
        .with(entity.id, pipeline_tracker.stage)

      expect(subject).to receive(:jid).and_return('jid')

      subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

      pipeline_tracker.reload

      expect(pipeline_tracker.status_name).to eq(:failed)
      expect(pipeline_tracker.jid).to eq('jid')
    end
  end
end
