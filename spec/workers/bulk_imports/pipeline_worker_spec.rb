# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::PipelineWorker, feature_category: :importers do
  let(:pipeline_class) do
    Class.new do
      def initialize(_); end

      def run; end

      def self.file_extraction_pipeline?
        false
      end
    end
  end

  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: bulk_import) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import) }

  let(:pipeline_tracker) do
    create(
      :bulk_import_tracker,
      entity: entity,
      pipeline_name: 'FakePipeline',
      status_event: 'enqueue'
    )
  end

  before do
    stub_const('FakePipeline', pipeline_class)

    allow(entity).to receive(:pipeline_exists?).with('FakePipeline').and_return(true)
    allow_next_instance_of(BulkImports::Groups::Stage) do |instance|
      allow(instance).to receive(:pipelines)
        .and_return([{ stage: 0, pipeline: pipeline_class }])
    end
  end

  shared_examples 'successfully runs the pipeline' do
    it 'runs the given pipeline successfully' do
      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger)
          .to receive(:info)
          .with(
            hash_including(
              'pipeline_name' => 'FakePipeline',
              'bulk_import_id' => entity.bulk_import_id,
              'bulk_import_entity_id' => entity.id,
              'bulk_import_entity_type' => entity.source_type,
              'source_full_path' => entity.source_full_path
            )
          )
      end

      expect(BulkImports::EntityWorker)
        .to receive(:perform_async)
        .with(entity.id, pipeline_tracker.stage)

      allow(subject).to receive(:jid).and_return('jid')

      subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

      pipeline_tracker.reload

      expect(pipeline_tracker.status_name).to eq(:finished)
      expect(pipeline_tracker.jid).to eq('jid')
    end
  end

  it_behaves_like 'successfully runs the pipeline'

  context 'when exclusive lease cannot be obtained' do
    it 'does not run the pipeline' do
      expect(subject).to receive(:try_obtain_lease).and_return(false)
      expect(subject).not_to receive(:run)

      subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)
    end
  end

  context 'when the pipeline raises an exception' do
    it 'logs the error' do
      pipeline_tracker = create(
        :bulk_import_tracker,
        entity: entity,
        pipeline_name: 'FakePipeline',
        status_event: 'enqueue'
      )

      allow(subject).to receive(:jid).and_return('jid')

      expect_next_instance_of(pipeline_class) do |pipeline|
        expect(pipeline)
          .to receive(:run)
          .and_raise(StandardError, 'Error!')
      end

      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger)
          .to receive(:error)
          .with(
            hash_including(
              'pipeline_name' => 'FakePipeline',
              'bulk_import_entity_id' => entity.id,
              'bulk_import_id' => entity.bulk_import_id,
              'bulk_import_entity_type' => entity.source_type,
              'source_full_path' => entity.source_full_path,
              'class' => 'BulkImports::PipelineWorker',
              'exception.backtrace' => anything,
              'exception.message' => 'Error!',
              'message' => 'Pipeline failed',
              'source_version' => entity.bulk_import.source_version_info.to_s,
              'importer' => 'gitlab_migration'
            )
          )
      end

      expect(Gitlab::ErrorTracking)
        .to receive(:track_exception)
        .with(
          instance_of(StandardError),
          hash_including(
            'bulk_import_entity_id' => entity.id,
            'bulk_import_id' => entity.bulk_import.id,
            'bulk_import_entity_type' => entity.source_type,
            'source_full_path' => entity.source_full_path,
            'pipeline_name' => pipeline_tracker.pipeline_name,
            'importer' => 'gitlab_migration',
            'source_version' => entity.bulk_import.source_version_info.to_s
          )
        )

      expect(BulkImports::EntityWorker)
        .to receive(:perform_async)
        .with(entity.id, pipeline_tracker.stage)

      expect(BulkImports::Failure)
        .to receive(:create)
        .with(
          a_hash_including(
            bulk_import_entity_id: entity.id,
            pipeline_class: 'FakePipeline',
            pipeline_step: 'pipeline_worker_run',
            exception_class: 'StandardError',
            exception_message: 'Error!',
            correlation_id_value: anything
          )
        )

      subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

      pipeline_tracker.reload

      expect(pipeline_tracker.status_name).to eq(:failed)
      expect(pipeline_tracker.jid).to eq('jid')
    end

    shared_examples 'successfully runs the pipeline' do
      it 'runs the given pipeline successfully' do
        expect_next_instance_of(Gitlab::Import::Logger) do |logger|
          expect(logger)
            .to receive(:info)
            .with(
              hash_including(
                'pipeline_name' => 'FakePipeline',
                'bulk_import_id' => entity.bulk_import_id,
                'bulk_import_entity_id' => entity.id,
                'bulk_import_entity_type' => entity.source_type,
                'source_full_path' => entity.source_full_path
              )
            )
        end

        expect(BulkImports::EntityWorker)
          .to receive(:perform_async)
          .with(entity.id, pipeline_tracker.stage)

        allow(subject).to receive(:jid).and_return('jid')

        subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

        pipeline_tracker.reload

        expect(pipeline_tracker.status_name).to eq(:finished)
        expect(pipeline_tracker.jid).to eq('jid')
      end
    end

    context 'when enqueued pipeline cannot be found' do
      shared_examples 'logs the error' do
        it 'logs the error' do
          expect_next_instance_of(Gitlab::Import::Logger) do |logger|
            status = pipeline_tracker.human_status_name

            expect(logger)
              .to receive(:error)
              .with(
                hash_including(
                  'bulk_import_entity_id' => entity.id,
                  'bulk_import_id' => entity.bulk_import_id,
                  'bulk_import_entity_type' => entity.source_type,
                  'pipeline_tracker_id' => pipeline_tracker.id,
                  'pipeline_tracker_state' => status,
                  'pipeline_name' => pipeline_tracker.pipeline_name,
                  'source_full_path' => entity.source_full_path,
                  'source_version' => entity.bulk_import.source_version_info.to_s,
                  'importer' => 'gitlab_migration',
                  'message' => "Pipeline in #{status} state instead of expected enqueued state"
                )
              )
          end

          expect(BulkImports::EntityWorker)
            .to receive(:perform_async)
            .with(entity.id, pipeline_tracker.stage)

          subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)
        end
      end

      context 'when pipeline is finished' do
        let(:pipeline_tracker) do
          create(
            :bulk_import_tracker,
            :finished,
            entity: entity,
            pipeline_name: 'FakePipeline'
          )
        end

        include_examples 'logs the error'
      end

      context 'when pipeline is skipped' do
        let(:pipeline_tracker) do
          create(
            :bulk_import_tracker,
            :skipped,
            entity: entity,
            pipeline_name: 'FakePipeline'
          )
        end

        include_examples 'logs the error'
      end

      context 'when tracker is started' do
        it 'marks tracker as failed' do
          pipeline_tracker = create(
            :bulk_import_tracker,
            :started,
            entity: entity,
            pipeline_name: 'FakePipeline'
          )

          subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

          expect(pipeline_tracker.reload.failed?).to eq(true)
        end
      end
    end

    context 'when entity is failed' do
      it 'marks tracker as skipped and logs the skip' do
        pipeline_tracker = create(
          :bulk_import_tracker,
          entity: entity,
          pipeline_name: 'FakePipeline',
          status_event: 'enqueue'
        )

        entity.update!(status: -1)

        expect_next_instance_of(Gitlab::Import::Logger) do |logger|
          allow(logger).to receive(:info)

          expect(logger)
            .to receive(:info)
            .with(
              hash_including(
                'pipeline_name' => 'FakePipeline',
                'bulk_import_entity_id' => entity.id,
                'bulk_import_id' => entity.bulk_import_id,
                'bulk_import_entity_type' => entity.source_type,
                'source_full_path' => entity.source_full_path,
                'message' => 'Skipping pipeline due to failed entity'
              )
            )
        end

        subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

        expect(pipeline_tracker.reload.status_name).to eq(:skipped)
      end
    end

    context 'when retry pipeline error is raised' do
      let(:pipeline_tracker) do
        create(
          :bulk_import_tracker,
          entity: entity,
          pipeline_name: 'FakePipeline',
          status_event: 'enqueue'
        )
      end

      let(:exception) do
        BulkImports::RetryPipelineError.new('Error!', 60)
      end

      before do
        allow(subject).to receive(:jid).and_return('jid')

        expect_next_instance_of(pipeline_class) do |pipeline|
          expect(pipeline)
            .to receive(:run)
            .and_raise(exception)
        end
      end

      it 'reenqueues the worker' do
        expect_any_instance_of(BulkImports::Tracker) do |tracker|
          expect(tracker).to receive(:retry).and_call_original
        end

        expect_next_instance_of(Gitlab::Import::Logger) do |logger|
          expect(logger)
            .to receive(:info)
            .with(
              hash_including(
                'pipeline_name' => 'FakePipeline',
                'bulk_import_entity_id' => entity.id,
                'bulk_import_id' => entity.bulk_import_id,
                'bulk_import_entity_type' => entity.source_type,
                'source_full_path' => entity.source_full_path
              )
            )
        end

        expect(described_class)
          .to receive(:perform_in)
          .with(
            60.seconds,
            pipeline_tracker.id,
            pipeline_tracker.stage,
            pipeline_tracker.entity.id
          )

        subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

        pipeline_tracker.reload

        expect(pipeline_tracker.enqueued?).to be_truthy
      end
    end
  end

  context 'when file extraction pipeline' do
    let(:file_extraction_pipeline) do
      Class.new do
        def initialize(_); end

        def run; end

        def self.file_extraction_pipeline?
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
        pipeline_name: 'NdjsonPipeline',
        status_event: 'enqueue'
      )
    end

    before do
      stub_const('NdjsonPipeline', file_extraction_pipeline)

      allow_next_instance_of(BulkImports::Groups::Stage) do |instance|
        allow(instance).to receive(:pipelines)
                             .and_return([{ stage: 0, pipeline: file_extraction_pipeline }])
      end
    end

    it 'runs the pipeline successfully' do
      allow_next_instance_of(BulkImports::ExportStatus) do |status|
        allow(status).to receive(:started?).and_return(false)
        allow(status).to receive(:empty?).and_return(false)
        allow(status).to receive(:failed?).and_return(false)
      end

      subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

      expect(pipeline_tracker.reload.status_name).to eq(:finished)
    end

    context 'when export status is started' do
      it 'reenqueues pipeline worker' do
        allow_next_instance_of(BulkImports::ExportStatus) do |status|
          allow(status).to receive(:started?).and_return(true)
          allow(status).to receive(:empty?).and_return(false)
          allow(status).to receive(:failed?).and_return(false)
        end

        expect(described_class)
          .to receive(:perform_in)
          .with(
            described_class::FILE_EXTRACTION_PIPELINE_PERFORM_DELAY,
            pipeline_tracker.id,
            pipeline_tracker.stage,
            entity.id
          )

        subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)
      end
    end

    context 'when export status is empty' do
      before do
        allow_next_instance_of(BulkImports::ExportStatus) do |status|
          allow(status).to receive(:started?).and_return(false)
          allow(status).to receive(:empty?).and_return(true)
          allow(status).to receive(:failed?).and_return(false)
        end

        pipeline_tracker.update!(created_at: created_at)
      end

      context 'when timeout is not reached' do
        let(:created_at) { 1.minute.ago }

        it 'reenqueues pipeline worker' do
          expect(described_class)
            .to receive(:perform_in)
            .with(
              described_class::FILE_EXTRACTION_PIPELINE_PERFORM_DELAY,
              pipeline_tracker.id,
              pipeline_tracker.stage,
              entity.id
            )

          subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

          expect(pipeline_tracker.reload.status_name).to eq(:enqueued)
        end
      end

      context 'when empty export timeout is reached' do
        let(:created_at) { 10.minutes.ago }

        it 'marks as failed and logs the error' do
          expect_next_instance_of(Gitlab::Import::Logger) do |logger|
            expect(logger)
              .to receive(:error)
              .with(
                hash_including(
                  'pipeline_name' => 'NdjsonPipeline',
                  'bulk_import_entity_id' => entity.id,
                  'bulk_import_id' => entity.bulk_import_id,
                  'bulk_import_entity_type' => entity.source_type,
                  'source_full_path' => entity.source_full_path,
                  'class' => 'BulkImports::PipelineWorker',
                  'exception.backtrace' => anything,
                  'exception.class' => 'BulkImports::Pipeline::ExpiredError',
                  'exception.message' => 'Empty export status on source instance',
                  'importer' => 'gitlab_migration',
                  'message' => 'Pipeline failed',
                  'source_version' => entity.bulk_import.source_version_info.to_s
                )
              )
          end

          subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

          expect(pipeline_tracker.reload.status_name).to eq(:failed)
        end
      end

      context 'when tracker created_at is nil' do
        let(:created_at) { nil }

        it 'falls back to entity created_at' do
          entity.update!(created_at: 10.minutes.ago)

          expect_next_instance_of(Gitlab::Import::Logger) do |logger|
            expect(logger)
              .to receive(:error)
              .with(
                hash_including('exception.message' => 'Empty export status on source instance')
              )
          end

          subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

          expect(pipeline_tracker.reload.status_name).to eq(:failed)
        end
      end
    end

    context 'when job reaches timeout' do
      it 'marks as failed and logs the error' do
        old_created_at = pipeline_tracker.created_at
        pipeline_tracker.update!(created_at: (BulkImports::Pipeline::NDJSON_EXPORT_TIMEOUT + 1.hour).ago)

        expect_next_instance_of(Gitlab::Import::Logger) do |logger|
          expect(logger)
            .to receive(:error)
            .with(
              hash_including(
                'pipeline_name' => 'NdjsonPipeline',
                'bulk_import_entity_id' => entity.id,
                'bulk_import_id' => entity.bulk_import_id,
                'bulk_import_entity_type' => entity.source_type,
                'source_full_path' => entity.source_full_path,
                'class' => 'BulkImports::PipelineWorker',
                'exception.backtrace' => anything,
                'exception.class' => 'BulkImports::Pipeline::ExpiredError',
                'exception.message' => 'Pipeline timeout',
                'importer' => 'gitlab_migration',
                'message' => 'Pipeline failed',
                'source_version' => entity.bulk_import.source_version_info.to_s
              )
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
              hash_including(
                'pipeline_name' => 'NdjsonPipeline',
                'bulk_import_entity_id' => entity.id,
                'bulk_import_id' => entity.bulk_import_id,
                'bulk_import_entity_type' => entity.source_type,
                'source_full_path' => entity.source_full_path,
                'exception.backtrace' => anything,
                'exception.class' => 'BulkImports::Pipeline::FailedError',
                'exception.message' => 'Export from source instance failed: Error!',
                'importer' => 'gitlab_migration',
                'source_version' => entity.bulk_import.source_version_info.to_s
              )
            )
        end

        subject.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

        expect(pipeline_tracker.reload.status_name).to eq(:failed)
      end
    end
  end
end
