# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::PipelineWorker do
  let(:pipeline_class) do
    Class.new do
      def initialize(_); end

      def run; end

      def self.ndjson_pipeline?
        false
      end
    end
  end

  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: bulk_import) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import) }

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
      .twice
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

  context 'when ndjson pipeline' do
    let(:ndjson_pipeline) do
      Class.new do
        def initialize(_); end

        def run; end

        def self.ndjson_pipeline?
          true
        end

        def self.relation
          'test'
        end
      end
    end

    let(:pipeline_tracker) do
      create(
        :bulk_import_tracker,
        entity: entity,
        pipeline_name: 'NdjsonPipeline'
      )
    end

    before do
      stub_const('NdjsonPipeline', ndjson_pipeline)
      allow(BulkImports::Stage)
        .to receive(:pipeline_exists?)
        .with('NdjsonPipeline')
        .and_return(true)
    end

    it 'runs the pipeline successfully' do
      allow_next_instance_of(BulkImports::ExportStatus) do |status|
        allow(status).to receive(:started?).and_return(false)
        allow(status).to receive(:failed?).and_return(false)
      end

      subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

      expect(pipeline_tracker.reload.status_name).to eq(:finished)
    end

    context 'when export status is started' do
      it 'reenqueues pipeline worker' do
        allow_next_instance_of(BulkImports::ExportStatus) do |status|
          allow(status).to receive(:started?).and_return(true)
          allow(status).to receive(:failed?).and_return(false)
        end

        expect(described_class)
          .to receive(:perform_in)
          .with(
            described_class::NDJSON_PIPELINE_PERFORM_DELAY,
            pipeline_tracker.id,
            pipeline_tracker.stage,
            entity.id
          )

        subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)
      end
    end

    context 'when job reaches timeout' do
      it 'marks as failed and logs the error' do
        old_created_at = entity.created_at
        entity.update!(created_at: (BulkImports::Pipeline::NDJSON_EXPORT_TIMEOUT + 1.hour).ago)

        expect_next_instance_of(Gitlab::Import::Logger) do |logger|
          expect(logger)
            .to receive(:error)
            .with(
              worker: described_class.name,
              pipeline_name: 'NdjsonPipeline',
              entity_id: entity.id,
              message: 'Pipeline timeout'
            )
        end

        subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

        expect(pipeline_tracker.reload.status_name).to eq(:failed)

        entity.update!(created_at: old_created_at)
      end
    end

    context 'when export status is failed' do
      it 'marks as failed and logs the error' do
        allow_next_instance_of(BulkImports::ExportStatus) do |status|
          allow(status).to receive(:failed?).and_return(true)
          allow(status).to receive(:error).and_return('Error!')
        end

        expect_next_instance_of(Gitlab::Import::Logger) do |logger|
          expect(logger)
            .to receive(:error)
            .with(
              worker: described_class.name,
              pipeline_name: 'NdjsonPipeline',
              entity_id: entity.id,
              message: 'Error!'
            )
        end

        subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

        expect(pipeline_tracker.reload.status_name).to eq(:failed)
      end
    end
  end
end
