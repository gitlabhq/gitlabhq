# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::PipelineWorker, feature_category: :importers do
  let(:pipeline_class) do
    Class.new do
      def initialize(_); end

      def run; end

      def self.relation
        'labels'
      end

      def self.file_extraction_pipeline?
        false
      end

      def self.abort_on_failure?
        false
      end
    end
  end

  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: bulk_import) }
  let_it_be_with_reload(:entity) { create(:bulk_import_entity, bulk_import: bulk_import) }

  let(:pipeline_tracker) do
    create(
      :bulk_import_tracker,
      entity: entity,
      pipeline_name: 'FakePipeline',
      status_event: 'enqueue'
    )
  end

  let(:worker) { described_class.new }

  before do
    stub_const('FakePipeline', pipeline_class)

    allow(entity).to receive(:pipeline_exists?).with('FakePipeline').and_return(true)
    allow_next_instance_of(BulkImports::Groups::Stage) do |instance|
      allow(instance).to receive(:pipelines)
        .and_return([{ stage: 0, pipeline: pipeline_class }])
    end
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [pipeline_tracker.id, pipeline_tracker.stage, entity.id] }

    it 'runs the pipeline and sets tracker to finished' do
      allow(worker).to receive(:jid).and_return('jid')

      perform_multiple(job_args, worker: worker)

      pipeline_tracker.reload

      expect(pipeline_tracker.status_name).to eq(:finished)
      expect(pipeline_tracker.jid).to eq('jid')
    end
  end

  it 'runs the given pipeline successfully' do
    expect_next_instance_of(BulkImports::Logger) do |logger|
      expect(logger).to receive(:with_tracker).with(pipeline_tracker).and_call_original
      expect(logger).to receive(:with_entity).with(pipeline_tracker.entity).and_call_original
      expect(logger).to receive(:info)
    end

    allow(worker).to receive(:jid).and_return('jid')

    worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

    pipeline_tracker.reload

    expect(pipeline_tracker.status_name).to eq(:finished)
    expect(pipeline_tracker.jid).to eq('jid')
  end

  context 'when exclusive lease cannot be obtained' do
    it 'does not run the pipeline' do
      expect(worker).to receive(:try_obtain_lease).and_return(false)
      expect(worker).not_to receive(:run)

      worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)
    end
  end

  describe '.sidekiq_retries_exhausted' do
    it 'logs and sets status as failed' do
      job = { 'args' => [pipeline_tracker.id, pipeline_tracker.stage, entity.id] }

      expect_next_instance_of(BulkImports::Logger) do |logger|
        expect(logger).to receive(:with_tracker).with(pipeline_tracker).and_call_original
        expect(logger).to receive(:with_entity).with(pipeline_tracker.entity).and_call_original
        expect(logger).to receive(:error)
      end

      expect(Gitlab::ErrorTracking)
        .to receive(:track_exception)
        .with(
          instance_of(StandardError),
          hash_including(
            bulk_import_entity_id: entity.id,
            bulk_import_id: entity.bulk_import.id,
            bulk_import_entity_type: entity.source_type,
            source_full_path: entity.source_full_path,
            pipeline_class: pipeline_tracker.pipeline_name,
            importer: 'gitlab_migration',
            source_version: entity.bulk_import.source_version_info.to_s
          )
        )

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

      expect_next_instance_of(described_class) do |worker|
        expect(worker).to receive(:perform_failure).with(pipeline_tracker.id, entity.id, StandardError)
          .and_call_original
        allow(worker).to receive(:jid).and_return('jid')
      end

      described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new('Error!'))

      pipeline_tracker.reload

      expect(pipeline_tracker.status_name).to eq(:failed)
      expect(pipeline_tracker.jid).to eq('jid')
      expect(entity.reload.status_name).to eq(:created)
    end

    context 'when pipeline has abort_on_failure' do
      before do
        allow(pipeline_class).to receive(:abort_on_failure?).and_return(true)
      end

      it 'marks entity as failed' do
        job = { 'args' => [pipeline_tracker.id, pipeline_tracker.stage, entity.id] }

        described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new('Error!'))

        expect(entity.reload.status_name).to eq(:failed)
      end
    end
  end

  describe '.sidekiq_interruptions_exhausted' do
    it 'logs and sets status as failed' do
      job = { 'args' => [pipeline_tracker.id, pipeline_tracker.stage, entity.id] }

      expect(BulkImports::Failure).to receive(:create).with(hash_including(
        bulk_import_entity_id: entity.id,
        exception_class: 'Import::Exceptions::SidekiqExhaustedInterruptionsError'
      ))

      described_class.interruptions_exhausted_block.call(job)
      expect(pipeline_tracker.reload).to be_failed
    end
  end

  context 'with stop signal from database health check' do
    let(:setter) { instance_double('Sidekiq::Job::Setter') }

    around do |example|
      with_sidekiq_server_middleware do |chain|
        chain.add Gitlab::SidekiqMiddleware::SkipJobs
        Sidekiq::Testing.inline! { example.run }
      end
    end

    before do
      stub_feature_flags("drop_sidekiq_jobs_#{described_class.name}": false)

      stop_signal = instance_double("Gitlab::Database::HealthStatus::Signals::Stop", stop?: true)
      allow(Gitlab::Database::HealthStatus).to receive(:evaluate).and_return([stop_signal])
    end

    it 'defers the job by set time' do
      expect_next_instance_of(described_class) do |worker|
        expect(worker).not_to receive(:perform).with(pipeline_tracker.id, pipeline_tracker.stage, entity.id)
      end

      expect(described_class).to receive(:deferred).and_return(setter)
      expect(setter).to receive(:perform_in).with(
        described_class::DEFER_ON_HEALTH_DELAY,
        pipeline_tracker.id,
        pipeline_tracker.stage,
        entity.id
      )

      described_class.perform_async(pipeline_tracker.id, pipeline_tracker.stage, entity.id)
    end

    it 'lazy evaluates schema and tables', :aggregate_failures do
      block = described_class.database_health_check_attrs[:block]

      job_args = [pipeline_tracker.id, pipeline_tracker.stage, entity.id]

      schema, table = block.call([job_args])

      expect(schema).to eq(:gitlab_main_cell)
      expect(table).to eq(['labels'])
    end

    context 'when `bulk_import_deferred_workers` feature flag is disabled' do
      it 'does not defer job execution' do
        stub_feature_flags(bulk_import_deferred_workers: false)

        expect_next_instance_of(described_class) do |worker|
          expect(worker).to receive(:perform).with(pipeline_tracker.id, pipeline_tracker.stage, entity.id)
        end

        expect(described_class).not_to receive(:perform_in)

        described_class.perform_async(pipeline_tracker.id, pipeline_tracker.stage, entity.id)
      end
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

    it 'no-ops and returns' do
      expect(described_class).not_to receive(:run)

      worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)
    end
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

    it 'no-ops and returns' do
      expect(described_class).not_to receive(:run)

      worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)
    end
  end

  context 'when pipeline is canceled' do
    let(:pipeline_tracker) do
      create(
        :bulk_import_tracker,
        :canceled,
        entity: entity,
        pipeline_name: 'FakePipeline'
      )
    end

    it 'no-ops and returns' do
      expect(described_class).not_to receive(:run)

      worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)
    end
  end

  context 'when tracker is started' do
    it 'runs the pipeline' do
      pipeline_tracker = create(
        :bulk_import_tracker,
        :started,
        entity: entity,
        pipeline_name: 'FakePipeline'
      )

      worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

      expect(pipeline_tracker.reload.finished?).to eq(true)
    end
  end

  describe '#perform' do
    context 'when entity is failed' do
      before do
        entity.update!(status: -1)
      end

      it 'marks tracker as skipped and logs the skip' do
        pipeline_tracker = create(
          :bulk_import_tracker,
          entity: entity,
          pipeline_name: 'FakePipeline',
          status_event: 'enqueue'
        )

        expect_next_instance_of(BulkImports::Logger) do |logger|
          allow(logger).to receive(:info)

          expect(logger)
            .to receive(:info)
            .with(hash_including(message: 'Skipping pipeline due to failed entity'))
        end

        worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

        expect(pipeline_tracker.reload.status_name).to eq(:skipped)
      end
    end

    context 'when entity is canceled' do
      it 'marks tracker as canceled and logs the cancel' do
        entity.update!(status: -2)

        pipeline_tracker = create(
          :bulk_import_tracker,
          entity: entity,
          pipeline_name: 'FakePipeline',
          status_event: 'enqueue'
        )

        expect_next_instance_of(BulkImports::Logger) do |logger|
          allow(logger).to receive(:info)

          expect(logger)
            .to receive(:info)
            .with(hash_including(message: 'Canceling pipeline due to canceled entity'))
        end

        worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

        expect(pipeline_tracker.reload.status_name).to eq(:canceled)
      end
    end

    context 'when entity is timeout' do
      it 'marks tracker as timeout and logs the timeout' do
        entity.update!(status: 3)

        pipeline_tracker = create(
          :bulk_import_tracker,
          entity: entity,
          pipeline_name: 'FakePipeline',
          status_event: 'enqueue'
        )

        expect_next_instance_of(BulkImports::Logger) do |logger|
          allow(logger).to receive(:info)

          expect(logger)
            .to receive(:info)
            .with(hash_including(message: 'Timeout pipeline due to timeout entity'))
        end

        worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

        expect(pipeline_tracker.reload.status_name).to eq(:timeout)
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
        allow(worker).to receive(:jid).and_return('jid')

        expect_next_instance_of(pipeline_class) do |pipeline|
          expect(pipeline)
            .to receive(:run)
            .and_raise(exception)
        end
      end

      it 're_enqueues the worker' do
        expect_any_instance_of(BulkImports::Tracker) do |tracker|
          expect(tracker).to receive(:retry).and_call_original
        end

        expect_next_instance_of(BulkImports::Logger) do |logger|
          expect(logger).to receive(:with_tracker).and_call_original
          expect(logger).to receive(:with_entity).and_call_original
          expect(logger).to receive(:info)
        end

        expect(described_class)
          .to receive(:perform_in)
          .with(
            60.seconds,
            pipeline_tracker.id,
            pipeline_tracker.stage,
            pipeline_tracker.entity.id
          )

        worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

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
        allow(instance)
          .to receive(:pipelines)
          .and_return([{ stage: 0, pipeline: file_extraction_pipeline }])
      end
    end

    it 'runs the pipeline successfully' do
      allow_next_instance_of(BulkImports::ExportStatus) do |status|
        allow(status).to receive(:started?).and_return(false)
        allow(status).to receive(:empty?).and_return(false)
        allow(status).to receive(:failed?).and_return(false)
        allow(status).to receive(:batched?).and_return(false)
      end

      worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

      expect(pipeline_tracker.reload.status_name).to eq(:finished)
    end

    context 'when export status is started' do
      it 'reenqueues pipeline worker' do
        allow_next_instance_of(BulkImports::ExportStatus) do |status|
          allow(status).to receive(:started?).and_return(true)
          allow(status).to receive(:empty?).and_return(false)
          allow(status).to receive(:failed?).and_return(false)
          allow(status).to receive(:batched?).and_return(false)
        end

        expect(described_class)
          .to receive(:perform_in)
          .with(
            described_class::FILE_EXTRACTION_PIPELINE_PERFORM_DELAY,
            pipeline_tracker.id,
            pipeline_tracker.stage,
            entity.id
          )

        worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)
      end
    end

    context 'when export status is empty' do
      before do
        allow_next_instance_of(BulkImports::ExportStatus) do |status|
          allow(status).to receive(:started?).and_return(false)
          allow(status).to receive(:empty?).and_return(true)
          allow(status).to receive(:failed?).and_return(false)
          allow(status).to receive(:batched?).and_return(false)
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

          worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

          expect(pipeline_tracker.reload.status_name).to eq(:enqueued)
        end
      end

      context 'when empty export timeout is reached' do
        let(:created_at) { 10.minutes.ago }

        it 'raises sidekiq error' do
          expect { worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id) }
            .to raise_exception(BulkImports::Pipeline::ExpiredError)
        end
      end

      context 'when tracker created_at is nil' do
        let(:created_at) { nil }

        it 'falls back to entity created_at' do
          entity.update!(created_at: 10.minutes.ago)

          expect { worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id) }
            .to raise_exception(BulkImports::Pipeline::ExpiredError)
        end
      end
    end

    context 'when export status is failed' do
      it 'marks as failed and logs the error' do
        allow_next_instance_of(BulkImports::ExportStatus) do |status|
          allow(status).to receive(:failed?).and_return(true)
          allow(status).to receive(:error).and_return('Error!')
        end

        expect { worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id) }
          .to raise_exception(BulkImports::Pipeline::FailedError)
      end
    end

    context 'when export is batched', :aggregate_failures do
      let(:batches_count) { 3 }

      before do
        allow_next_instance_of(BulkImports::ExportStatus) do |status|
          allow(status).to receive(:batched?).and_return(true)
          allow(status).to receive(:batches_count).and_return(batches_count)
          allow(status).to receive(:started?).and_return(false)
          allow(status).to receive(:empty?).and_return(false)
          allow(status).to receive(:failed?).and_return(false)
        end
        allow(worker).to receive(:log_extra_metadata_on_done).and_call_original
      end

      it 'enqueues pipeline batches' do
        expect(BulkImports::PipelineBatchWorker).to receive(:perform_async).exactly(3).times
        expect(worker).to receive(:log_extra_metadata_on_done).with(:batched, true)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:tracker_batch_numbers_enqueued, [1, 2, 3])
        expect(worker).to receive(:log_extra_metadata_on_done).with(:tracker_final_batch_was_enqueued, true)

        worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

        pipeline_tracker.reload

        expect(pipeline_tracker.status_name).to eq(:started)
        expect(pipeline_tracker.batched).to eq(true)
        expect(pipeline_tracker.batches.pluck_batch_numbers).to contain_exactly(1, 2, 3)
        expect(described_class.jobs).to be_empty
      end

      it 'enqueues only missing pipelines batches' do
        create(:bulk_import_batch_tracker, tracker: pipeline_tracker, batch_number: 2)
        expect(BulkImports::PipelineBatchWorker).to receive(:perform_async).twice
        expect(worker).to receive(:log_extra_metadata_on_done).with(:tracker_batch_numbers_enqueued, [1, 3])
        expect(worker).to receive(:log_extra_metadata_on_done).with(:tracker_final_batch_was_enqueued, true)

        worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

        pipeline_tracker.reload

        expect(pipeline_tracker.status_name).to eq(:started)
        expect(pipeline_tracker.batched).to eq(true)
        expect(pipeline_tracker.batches.pluck_batch_numbers).to contain_exactly(1, 2, 3)
        expect(described_class.jobs).to be_empty
      end

      context 'when batches count is less than 1' do
        let(:batches_count) { 0 }

        it 'marks tracker as finished' do
          expect(worker).not_to receive(:enqueue_batches)

          worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

          expect(pipeline_tracker.reload.status_name).to eq(:finished)
        end
      end

      context 'when pipeline batch enqueuing should be limited' do
        using RSpec::Parameterized::TableSyntax

        before do
          allow(::Gitlab::CurrentSettings).to receive(:bulk_import_concurrent_pipeline_batch_limit).and_return(2)
        end

        it 'only enqueues limited batches and reenqueues itself' do
          expect(BulkImports::PipelineBatchWorker).to receive(:perform_async).twice
          expect(worker).to receive(:log_extra_metadata_on_done).with(:tracker_batch_numbers_enqueued, [1, 2])
          expect(worker).to receive(:log_extra_metadata_on_done).with(:tracker_final_batch_was_enqueued, false)

          worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

          pipeline_tracker.reload

          expect(pipeline_tracker.status_name).to eq(:started)
          expect(pipeline_tracker.batched).to eq(true)
          expect(pipeline_tracker.batches.pluck_batch_numbers).to contain_exactly(1, 2)
          expect(described_class.jobs).to contain_exactly(
            hash_including(
              'args' => [pipeline_tracker.id, pipeline_tracker.stage, entity.id],
              'scheduled_at' => be_within(1).of(10.seconds.from_now.to_i)
            )
          )
        end

        context 'when there is a batch in progress' do
          where(:status) { BulkImports::BatchTracker::IN_PROGRESS_STATES }

          with_them do
            before do
              create(:bulk_import_batch_tracker, status, batch_number: 1, tracker: pipeline_tracker)
            end

            it 'counts the in progress batch against the limit' do
              expect(BulkImports::PipelineBatchWorker).to receive(:perform_async).once
              expect(worker).to receive(:log_extra_metadata_on_done).with(:tracker_batch_numbers_enqueued, [2])
              expect(worker).to receive(:log_extra_metadata_on_done).with(:tracker_final_batch_was_enqueued, false)

              worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

              pipeline_tracker.reload

              expect(pipeline_tracker.status_name).to eq(:started)
              expect(pipeline_tracker.batched).to eq(true)
              expect(pipeline_tracker.batches.pluck_batch_numbers).to contain_exactly(1, 2)
              expect(described_class.jobs).to contain_exactly(
                hash_including(
                  'args' => [pipeline_tracker.id, pipeline_tracker.stage, entity.id],
                  'scheduled_at' => be_within(1).of(10.seconds.from_now.to_i)
                )
              )
            end
          end
        end

        context 'when there is a batch that has finished' do
          where(:status) do
            all_statuses = BulkImports::BatchTracker.state_machines[:status].states.map(&:name)
            all_statuses - BulkImports::BatchTracker::IN_PROGRESS_STATES
          end

          with_them do
            before do
              create(:bulk_import_batch_tracker, status, batch_number: 1, tracker: pipeline_tracker)
            end

            it 'does not count the finished batch against the limit' do
              expect(BulkImports::PipelineBatchWorker).to receive(:perform_async).twice
              expect(worker).to receive(:log_extra_metadata_on_done).with(:tracker_batch_numbers_enqueued, [2, 3])
              expect(worker).to receive(:log_extra_metadata_on_done).with(:tracker_final_batch_was_enqueued, true)

              worker.perform(pipeline_tracker.id, pipeline_tracker.stage, entity.id)

              pipeline_tracker.reload

              expect(pipeline_tracker.batches.pluck_batch_numbers).to contain_exactly(1, 2, 3)
              expect(described_class.jobs).to be_empty
            end
          end
        end
      end
    end
  end
end
