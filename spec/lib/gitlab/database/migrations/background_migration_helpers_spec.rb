# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::BackgroundMigrationHelpers do
  let(:model) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  describe '#bulk_queue_background_migration_jobs_by_range' do
    context 'when the model has an ID column' do
      let!(:id1) { create(:user).id }
      let!(:id2) { create(:user).id }
      let!(:id3) { create(:user).id }

      before do
        User.class_eval do
          include EachBatch
        end
      end

      context 'with enough rows to bulk queue jobs more than once' do
        before do
          stub_const('Gitlab::Database::Migrations::BackgroundMigrationHelpers::JOB_BUFFER_SIZE', 1)
        end

        it 'queues jobs correctly' do
          Sidekiq::Testing.fake! do
            model.bulk_queue_background_migration_jobs_by_range(User, 'FooJob', batch_size: 2)

            expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['FooJob', [id1, id2]])
            expect(BackgroundMigrationWorker.jobs[1]['args']).to eq(['FooJob', [id3, id3]])
          end
        end

        it 'queues jobs in groups of buffer size 1' do
          expect(BackgroundMigrationWorker).to receive(:bulk_perform_async).with([['FooJob', [id1, id2]]])
          expect(BackgroundMigrationWorker).to receive(:bulk_perform_async).with([['FooJob', [id3, id3]]])

          model.bulk_queue_background_migration_jobs_by_range(User, 'FooJob', batch_size: 2)
        end
      end

      context 'with not enough rows to bulk queue jobs more than once' do
        it 'queues jobs correctly' do
          Sidekiq::Testing.fake! do
            model.bulk_queue_background_migration_jobs_by_range(User, 'FooJob', batch_size: 2)

            expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['FooJob', [id1, id2]])
            expect(BackgroundMigrationWorker.jobs[1]['args']).to eq(['FooJob', [id3, id3]])
          end
        end

        it 'queues jobs in bulk all at once (big buffer size)' do
          expect(BackgroundMigrationWorker).to receive(:bulk_perform_async).with([['FooJob', [id1, id2]],
                                                                                  ['FooJob', [id3, id3]]])

          model.bulk_queue_background_migration_jobs_by_range(User, 'FooJob', batch_size: 2)
        end
      end

      context 'without specifying batch_size' do
        it 'queues jobs correctly' do
          Sidekiq::Testing.fake! do
            model.bulk_queue_background_migration_jobs_by_range(User, 'FooJob')

            expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['FooJob', [id1, id3]])
          end
        end
      end
    end

    context "when the model doesn't have an ID column" do
      it 'raises error (for now)' do
        expect do
          model.bulk_queue_background_migration_jobs_by_range(ProjectAuthorization, 'FooJob')
        end.to raise_error(StandardError, /does not have an ID/)
      end
    end
  end

  describe '#queue_background_migration_jobs_by_range_at_intervals' do
    context 'when the model has an ID column' do
      let!(:id1) { create(:user).id }
      let!(:id2) { create(:user).id }
      let!(:id3) { create(:user).id }

      around do |example|
        freeze_time { example.run }
      end

      before do
        User.class_eval do
          include EachBatch
        end
      end

      it 'returns the final expected delay' do
        Sidekiq::Testing.fake! do
          final_delay = model.queue_background_migration_jobs_by_range_at_intervals(User, 'FooJob', 10.minutes, batch_size: 2)

          expect(final_delay.to_f).to eq(20.minutes.to_f)
        end
      end

      it 'returns zero when nothing gets queued' do
        Sidekiq::Testing.fake! do
          final_delay = model.queue_background_migration_jobs_by_range_at_intervals(User.none, 'FooJob', 10.minutes)

          expect(final_delay).to eq(0)
        end
      end

      context 'with batch_size option' do
        it 'queues jobs correctly' do
          Sidekiq::Testing.fake! do
            model.queue_background_migration_jobs_by_range_at_intervals(User, 'FooJob', 10.minutes, batch_size: 2)

            expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['FooJob', [id1, id2]])
            expect(BackgroundMigrationWorker.jobs[0]['at']).to eq(10.minutes.from_now.to_f)
            expect(BackgroundMigrationWorker.jobs[1]['args']).to eq(['FooJob', [id3, id3]])
            expect(BackgroundMigrationWorker.jobs[1]['at']).to eq(20.minutes.from_now.to_f)
          end
        end
      end

      context 'without batch_size option' do
        it 'queues jobs correctly' do
          Sidekiq::Testing.fake! do
            model.queue_background_migration_jobs_by_range_at_intervals(User, 'FooJob', 10.minutes)

            expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['FooJob', [id1, id3]])
            expect(BackgroundMigrationWorker.jobs[0]['at']).to eq(10.minutes.from_now.to_f)
          end
        end
      end

      context 'with other_job_arguments option' do
        it 'queues jobs correctly' do
          Sidekiq::Testing.fake! do
            model.queue_background_migration_jobs_by_range_at_intervals(User, 'FooJob', 10.minutes, other_job_arguments: [1, 2])

            expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['FooJob', [id1, id3, 1, 2]])
            expect(BackgroundMigrationWorker.jobs[0]['at']).to eq(10.minutes.from_now.to_f)
          end
        end
      end

      context 'with initial_delay option' do
        it 'queues jobs correctly' do
          Sidekiq::Testing.fake! do
            model.queue_background_migration_jobs_by_range_at_intervals(User, 'FooJob', 10.minutes, other_job_arguments: [1, 2], initial_delay: 10.minutes)

            expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['FooJob', [id1, id3, 1, 2]])
            expect(BackgroundMigrationWorker.jobs[0]['at']).to eq(20.minutes.from_now.to_f)
          end
        end
      end

      context 'with track_jobs option' do
        it 'creates a record for each job in the database' do
          Sidekiq::Testing.fake! do
            expect do
              model.queue_background_migration_jobs_by_range_at_intervals(User, '::FooJob', 10.minutes,
                other_job_arguments: [1, 2], track_jobs: true)
            end.to change { Gitlab::Database::BackgroundMigrationJob.count }.from(0).to(1)

            expect(BackgroundMigrationWorker.jobs.size).to eq(1)

            tracked_job = Gitlab::Database::BackgroundMigrationJob.first

            expect(tracked_job.class_name).to eq('FooJob')
            expect(tracked_job.arguments).to eq([id1, id3, 1, 2])
            expect(tracked_job).to be_pending
          end
        end
      end

      context 'without track_jobs option' do
        it 'does not create records in the database' do
          Sidekiq::Testing.fake! do
            expect do
              model.queue_background_migration_jobs_by_range_at_intervals(User, 'FooJob', 10.minutes, other_job_arguments: [1, 2])
            end.not_to change { Gitlab::Database::BackgroundMigrationJob.count }

            expect(BackgroundMigrationWorker.jobs.size).to eq(1)
          end
        end
      end
    end

    context 'when the model specifies a primary_column_name' do
      let!(:id1) { create(:container_expiration_policy).id }
      let!(:id2) { create(:container_expiration_policy).id }
      let!(:id3) { create(:container_expiration_policy).id }

      around do |example|
        freeze_time { example.run }
      end

      before do
        ContainerExpirationPolicy.class_eval do
          include EachBatch
        end
      end

      it 'returns the final expected delay', :aggregate_failures do
        Sidekiq::Testing.fake! do
          final_delay = model.queue_background_migration_jobs_by_range_at_intervals(ContainerExpirationPolicy, 'FooJob', 10.minutes, batch_size: 2, primary_column_name: :project_id)

          expect(final_delay.to_f).to eq(20.minutes.to_f)
          expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['FooJob', [id1, id2]])
          expect(BackgroundMigrationWorker.jobs[0]['at']).to eq(10.minutes.from_now.to_f)
          expect(BackgroundMigrationWorker.jobs[1]['args']).to eq(['FooJob', [id3, id3]])
          expect(BackgroundMigrationWorker.jobs[1]['at']).to eq(20.minutes.from_now.to_f)
        end
      end

      context "when the primary_column_name is not an integer" do
        it 'raises error' do
          expect do
            model.queue_background_migration_jobs_by_range_at_intervals(ContainerExpirationPolicy, 'FooJob', 10.minutes, primary_column_name: :enabled)
          end.to raise_error(StandardError, /is not an integer column/)
        end
      end

      context "when the primary_column_name does not exist" do
        it 'raises error' do
          expect do
            model.queue_background_migration_jobs_by_range_at_intervals(ContainerExpirationPolicy, 'FooJob', 10.minutes, primary_column_name: :foo)
          end.to raise_error(StandardError, /does not have an ID column of foo/)
        end
      end
    end

    context "when the model doesn't have an ID or primary_column_name column" do
      it 'raises error (for now)' do
        expect do
          model.queue_background_migration_jobs_by_range_at_intervals(ProjectAuthorization, 'FooJob', 10.seconds)
        end.to raise_error(StandardError, /does not have an ID/)
      end
    end
  end

  describe '#requeue_background_migration_jobs_by_range_at_intervals' do
    let!(:job_class_name) { 'TestJob' }
    let!(:pending_job_1) { create(:background_migration_job, class_name: job_class_name, status: :pending, arguments: [1, 2]) }
    let!(:pending_job_2) { create(:background_migration_job, class_name: job_class_name, status: :pending, arguments: [3, 4]) }
    let!(:successful_job_1) { create(:background_migration_job, class_name: job_class_name, status: :succeeded, arguments: [5, 6]) }
    let!(:successful_job_2) { create(:background_migration_job, class_name: job_class_name, status: :succeeded, arguments: [7, 8]) }

    around do |example|
      freeze_time do
        Sidekiq::Testing.fake! do
          example.run
        end
      end
    end

    subject { model.requeue_background_migration_jobs_by_range_at_intervals(job_class_name, 10.minutes) }

    it 'returns the expected duration' do
      expect(subject).to eq(20.minutes)
    end

    context 'when nothing is queued' do
      subject { model.requeue_background_migration_jobs_by_range_at_intervals('FakeJob', 10.minutes) }

      it 'returns expected duration of zero when nothing gets queued' do
        expect(subject).to eq(0)
      end
    end

    it 'queues pending jobs' do
      subject

      expect(BackgroundMigrationWorker.jobs[0]['args']).to eq([job_class_name, [1, 2]])
      expect(BackgroundMigrationWorker.jobs[0]['at']).to be_nil
      expect(BackgroundMigrationWorker.jobs[1]['args']).to eq([job_class_name, [3, 4]])
      expect(BackgroundMigrationWorker.jobs[1]['at']).to eq(10.minutes.from_now.to_f)
    end

    context 'with batch_size option' do
      subject { model.requeue_background_migration_jobs_by_range_at_intervals(job_class_name, 10.minutes, batch_size: 1) }

      it 'returns the expected duration' do
        expect(subject).to eq(20.minutes)
      end

      it 'queues pending jobs' do
        subject

        expect(BackgroundMigrationWorker.jobs[0]['args']).to eq([job_class_name, [1, 2]])
        expect(BackgroundMigrationWorker.jobs[0]['at']).to be_nil
        expect(BackgroundMigrationWorker.jobs[1]['args']).to eq([job_class_name, [3, 4]])
        expect(BackgroundMigrationWorker.jobs[1]['at']).to eq(10.minutes.from_now.to_f)
      end

      it 'retrieve jobs in batches' do
        jobs = double('jobs')
        expect(Gitlab::Database::BackgroundMigrationJob).to receive(:pending) { jobs }
        allow(jobs).to receive(:where).with(class_name: job_class_name) { jobs }
        expect(jobs).to receive(:each_batch).with(of: 1)

        subject
      end
    end

    context 'with initial_delay option' do
      let_it_be(:initial_delay) { 3.minutes }

      subject { model.requeue_background_migration_jobs_by_range_at_intervals(job_class_name, 10.minutes, initial_delay: initial_delay) }

      it 'returns the expected duration' do
        expect(subject).to eq(23.minutes)
      end

      it 'queues pending jobs' do
        subject

        expect(BackgroundMigrationWorker.jobs[0]['args']).to eq([job_class_name, [1, 2]])
        expect(BackgroundMigrationWorker.jobs[0]['at']).to eq(3.minutes.from_now.to_f)
        expect(BackgroundMigrationWorker.jobs[1]['args']).to eq([job_class_name, [3, 4]])
        expect(BackgroundMigrationWorker.jobs[1]['at']).to eq(13.minutes.from_now.to_f)
      end

      context 'when nothing is queued' do
        subject { model.requeue_background_migration_jobs_by_range_at_intervals('FakeJob', 10.minutes) }

        it 'returns expected duration of zero when nothing gets queued' do
          expect(subject).to eq(0)
        end
      end
    end
  end

  describe '#perform_background_migration_inline?' do
    it 'returns true in a test environment' do
      stub_rails_env('test')

      expect(model.perform_background_migration_inline?).to eq(true)
    end

    it 'returns true in a development environment' do
      stub_rails_env('development')

      expect(model.perform_background_migration_inline?).to eq(true)
    end

    it 'returns false in a production environment' do
      stub_rails_env('production')

      expect(model.perform_background_migration_inline?).to eq(false)
    end
  end

  describe '#queue_batched_background_migration' do
    let(:pgclass_info) { instance_double('Gitlab::Database::PgClass', cardinality_estimate: 42) }

    before do
      allow(Gitlab::Database::PgClass).to receive(:for_table).and_call_original
    end

    context 'when such migration already exists' do
      it 'does not create duplicate migration' do
        create(
          :batched_background_migration,
          job_class_name: 'MyJobClass',
          table_name: :projects,
          column_name: :id,
          interval: 10.minutes,
          min_value: 5,
          max_value: 1005,
          batch_class_name: 'MyBatchClass',
          batch_size: 200,
          sub_batch_size: 20,
          job_arguments: [[:id], [:id_convert_to_bigint]]
        )

        expect do
          model.queue_batched_background_migration(
            'MyJobClass',
            :projects,
            :id,
            [:id], [:id_convert_to_bigint],
            job_interval: 5.minutes,
            batch_min_value: 5,
            batch_max_value: 1000,
            batch_class_name: 'MyBatchClass',
            batch_size: 100,
            sub_batch_size: 10)
        end.not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
      end
    end

    it 'creates the database record for the migration' do
      expect(Gitlab::Database::PgClass).to receive(:for_table).with(:projects).and_return(pgclass_info)

      expect do
        model.queue_batched_background_migration(
          'MyJobClass',
          :projects,
          :id,
          job_interval: 5.minutes,
          batch_min_value: 5,
          batch_max_value: 1000,
          batch_class_name: 'MyBatchClass',
          batch_size: 100,
          sub_batch_size: 10)
      end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

      expect(Gitlab::Database::BackgroundMigration::BatchedMigration.last).to have_attributes(
        job_class_name: 'MyJobClass',
        table_name: 'projects',
        column_name: 'id',
        interval: 300,
        min_value: 5,
        max_value: 1000,
        batch_class_name: 'MyBatchClass',
        batch_size: 100,
        sub_batch_size: 10,
        job_arguments: %w[],
        status: 'active',
        total_tuple_count: pgclass_info.cardinality_estimate)
    end

    context 'when the job interval is lower than the minimum' do
      let(:minimum_delay) { described_class::BATCH_MIN_DELAY }

      it 'sets the job interval to the minimum value' do
        expect do
          model.queue_batched_background_migration('MyJobClass', :events, :id, job_interval: minimum_delay - 1.minute)
        end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

        created_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.last

        expect(created_migration.interval).to eq(minimum_delay)
      end
    end

    context 'when additional arguments are passed to the method' do
      it 'saves the arguments on the database record' do
        expect do
          model.queue_batched_background_migration(
            'MyJobClass',
            :projects,
            :id,
            'my',
            'arguments',
            job_interval: 5.minutes,
            batch_max_value: 1000)
        end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

        expect(Gitlab::Database::BackgroundMigration::BatchedMigration.last).to have_attributes(
          job_class_name: 'MyJobClass',
          table_name: 'projects',
          column_name: 'id',
          interval: 300,
          min_value: 1,
          max_value: 1000,
          job_arguments: %w[my arguments])
      end
    end

    context 'when the max_value is not given' do
      context 'when records exist in the database' do
        let!(:event1) { create(:event) }
        let!(:event2) { create(:event) }
        let!(:event3) { create(:event) }

        it 'creates the record with the current max value' do
          expect do
            model.queue_batched_background_migration('MyJobClass', :events, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          created_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.last

          expect(created_migration.max_value).to eq(event3.id)
        end

        it 'creates the record with an active status' do
          expect do
            model.queue_batched_background_migration('MyJobClass', :events, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          expect(Gitlab::Database::BackgroundMigration::BatchedMigration.last).to be_active
        end
      end

      context 'when the database is empty' do
        it 'sets the max value to the min value' do
          expect do
            model.queue_batched_background_migration('MyJobClass', :events, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          created_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.last

          expect(created_migration.max_value).to eq(created_migration.min_value)
        end

        it 'creates the record with a finished status' do
          expect do
            model.queue_batched_background_migration('MyJobClass', :projects, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          expect(Gitlab::Database::BackgroundMigration::BatchedMigration.last).to be_finished
        end
      end
    end
  end

  describe '#migrate_async' do
    it 'calls BackgroundMigrationWorker.perform_async' do
      expect(BackgroundMigrationWorker).to receive(:perform_async).with("Class", "hello", "world")

      model.migrate_async("Class", "hello", "world")
    end

    it 'pushes a context with the current class name as caller_id' do
      expect(Gitlab::ApplicationContext).to receive(:with_context).with(caller_id: model.class.to_s)

      model.migrate_async('Class', 'hello', 'world')
    end
  end

  describe '#migrate_in' do
    it 'calls BackgroundMigrationWorker.perform_in' do
      expect(BackgroundMigrationWorker).to receive(:perform_in).with(10.minutes, 'Class', 'Hello', 'World')

      model.migrate_in(10.minutes, 'Class', 'Hello', 'World')
    end

    it 'pushes a context with the current class name as caller_id' do
      expect(Gitlab::ApplicationContext).to receive(:with_context).with(caller_id: model.class.to_s)

      model.migrate_in(10.minutes, 'Class', 'Hello', 'World')
    end
  end

  describe '#bulk_migrate_async' do
    it 'calls BackgroundMigrationWorker.bulk_perform_async' do
      expect(BackgroundMigrationWorker).to receive(:bulk_perform_async).with([%w(Class hello world)])

      model.bulk_migrate_async([%w(Class hello world)])
    end

    it 'pushes a context with the current class name as caller_id' do
      expect(Gitlab::ApplicationContext).to receive(:with_context).with(caller_id: model.class.to_s)

      model.bulk_migrate_async([%w(Class hello world)])
    end
  end

  describe '#bulk_migrate_in' do
    it 'calls BackgroundMigrationWorker.bulk_perform_in_' do
      expect(BackgroundMigrationWorker).to receive(:bulk_perform_in).with(10.minutes, [%w(Class hello world)])

      model.bulk_migrate_in(10.minutes, [%w(Class hello world)])
    end

    it 'pushes a context with the current class name as caller_id' do
      expect(Gitlab::ApplicationContext).to receive(:with_context).with(caller_id: model.class.to_s)

      model.bulk_migrate_in(10.minutes, [%w(Class hello world)])
    end
  end

  describe '#delete_queued_jobs' do
    let(:job1) { double }
    let(:job2) { double }

    it 'deletes all queued jobs for the given background migration' do
      expect(Gitlab::BackgroundMigration).to receive(:steal).with('BackgroundMigrationClassName') do |&block|
        expect(block.call(job1)).to be(false)
        expect(block.call(job2)).to be(false)
      end

      expect(job1).to receive(:delete)
      expect(job2).to receive(:delete)

      model.delete_queued_jobs('BackgroundMigrationClassName')
    end
  end

  describe '#finalized_background_migration' do
    include_context 'background migration job class'

    let!(:tracked_pending_job) { create(:background_migration_job, class_name: job_class_name, status: :pending, arguments: [1]) }
    let!(:tracked_successful_job) { create(:background_migration_job, class_name: job_class_name, status: :succeeded, arguments: [2]) }

    before do
      Sidekiq::Testing.disable! do
        BackgroundMigrationWorker.perform_async(job_class_name, [1, 2])
        BackgroundMigrationWorker.perform_async(job_class_name, [3, 4])
        BackgroundMigrationWorker.perform_in(10, job_class_name, [5, 6])
        BackgroundMigrationWorker.perform_in(20, job_class_name, [7, 8])
      end
    end

    it_behaves_like 'finalized tracked background migration' do
      before do
        model.finalize_background_migration(job_class_name)
      end
    end

    context 'when removing all tracked job records' do
      # Force pending jobs to remain pending.
      let!(:job_perform_method) { ->(*arguments) { } }

      before do
        model.finalize_background_migration(job_class_name, delete_tracking_jobs: %w[pending succeeded])
      end

      it_behaves_like 'finalized tracked background migration'
      it_behaves_like 'removed tracked jobs', 'pending'
      it_behaves_like 'removed tracked jobs', 'succeeded'
    end

    context 'when retaining all tracked job records' do
      before do
        model.finalize_background_migration(job_class_name, delete_tracking_jobs: false)
      end

      it_behaves_like 'finalized background migration'
      include_examples 'retained tracked jobs', 'succeeded'
    end

    context 'during retry race condition' do
      let(:queue_items_added) { [] }
      let!(:job_perform_method) do
        ->(*arguments) do
          Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
            RSpec.current_example.example_group_instance.job_class_name,
            arguments
          )

          # Mock another process pushing queue jobs.
          queue_items_added = RSpec.current_example.example_group_instance.queue_items_added
          if queue_items_added.count < 10
            Sidekiq::Testing.disable! do
              job_class_name = RSpec.current_example.example_group_instance.job_class_name
              queue_items_added << BackgroundMigrationWorker.perform_async(job_class_name, [Time.current])
              queue_items_added << BackgroundMigrationWorker.perform_in(10, job_class_name, [Time.current])
            end
          end
        end
      end

      it_behaves_like 'finalized tracked background migration' do
        before do
          model.finalize_background_migration(job_class_name, delete_tracking_jobs: ['succeeded'])
        end
      end
    end
  end

  describe '#delete_job_tracking' do
    let!(:job_class_name) { 'TestJob' }

    let!(:tracked_pending_job) { create(:background_migration_job, class_name: job_class_name, status: :pending, arguments: [1]) }
    let!(:tracked_successful_job) { create(:background_migration_job, class_name: job_class_name, status: :succeeded, arguments: [2]) }

    context 'with default status' do
      before do
        model.delete_job_tracking(job_class_name)
      end

      include_examples 'retained tracked jobs', 'pending'
      include_examples 'removed tracked jobs', 'succeeded'
    end

    context 'with explicit status' do
      before do
        model.delete_job_tracking(job_class_name, status: %w[pending succeeded])
      end

      include_examples 'removed tracked jobs', 'pending'
      include_examples 'removed tracked jobs', 'succeeded'
    end
  end
end
