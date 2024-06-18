# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::BackgroundMigrationHelpers do
  let(:base_class) { ActiveRecord::Migration }

  let(:model) do
    base_class.new
      .extend(described_class)
      .extend(Gitlab::Database::Migrations::ReestablishedConnectionStack)
  end

  shared_examples_for 'helpers that enqueue background migrations' do |worker_class, connection_class, tracking_database|
    before do
      allow(model).to receive(:tracking_database).and_return(tracking_database)
      allow(connection_class.connection.load_balancer.configuration)
        .to receive(:use_dedicated_connection?).and_return(true)

      allow(model).to receive(:connection).and_return(connection_class.connection)
    end

    describe '#queue_background_migration_jobs_by_range_at_intervals' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      context 'when the model has an ID column' do
        let!(:id1) { create(:user).id }
        let!(:id2) { create(:user).id }
        let!(:id3) { create(:user).id }

        around do |example|
          freeze_time { example.run }
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

        context 'when the delay_interval is smaller than the minimum' do
          it 'sets the delay_interval to the minimum value' do
            Sidekiq::Testing.fake! do
              final_delay = model.queue_background_migration_jobs_by_range_at_intervals(User, 'FooJob', 1.minute, batch_size: 2)

              expect(worker_class.jobs[0]['args']).to eq(['FooJob', [id1, id2]])
              expect(worker_class.jobs[0]['at']).to eq(2.minutes.from_now.to_f)
              expect(worker_class.jobs[1]['args']).to eq(['FooJob', [id3, id3]])
              expect(worker_class.jobs[1]['at']).to eq(4.minutes.from_now.to_f)

              expect(final_delay.to_f).to eq(4.minutes.to_f)
            end
          end
        end

        context 'with batch_size option' do
          it 'queues jobs correctly' do
            Sidekiq::Testing.fake! do
              model.queue_background_migration_jobs_by_range_at_intervals(User, 'FooJob', 10.minutes, batch_size: 2)

              expect(worker_class.jobs[0]['args']).to eq(['FooJob', [id1, id2]])
              expect(worker_class.jobs[0]['at']).to eq(10.minutes.from_now.to_f)
              expect(worker_class.jobs[1]['args']).to eq(['FooJob', [id3, id3]])
              expect(worker_class.jobs[1]['at']).to eq(20.minutes.from_now.to_f)
            end
          end
        end

        context 'without batch_size option' do
          it 'queues jobs correctly' do
            Sidekiq::Testing.fake! do
              model.queue_background_migration_jobs_by_range_at_intervals(User, 'FooJob', 10.minutes)

              expect(worker_class.jobs[0]['args']).to eq(['FooJob', [id1, id3]])
              expect(worker_class.jobs[0]['at']).to eq(10.minutes.from_now.to_f)
            end
          end
        end

        context 'with other_job_arguments option' do
          it 'queues jobs correctly' do
            Sidekiq::Testing.fake! do
              model.queue_background_migration_jobs_by_range_at_intervals(User, 'FooJob', 10.minutes, other_job_arguments: [1, 2])

              expect(worker_class.jobs[0]['args']).to eq(['FooJob', [id1, id3, 1, 2]])
              expect(worker_class.jobs[0]['at']).to eq(10.minutes.from_now.to_f)
            end
          end
        end

        context 'with initial_delay option' do
          it 'queues jobs correctly' do
            Sidekiq::Testing.fake! do
              model.queue_background_migration_jobs_by_range_at_intervals(User, 'FooJob', 10.minutes, other_job_arguments: [1, 2], initial_delay: 10.minutes)

              expect(worker_class.jobs[0]['args']).to eq(['FooJob', [id1, id3, 1, 2]])
              expect(worker_class.jobs[0]['at']).to eq(20.minutes.from_now.to_f)
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

              expect(worker_class.jobs.size).to eq(1)

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

              expect(worker_class.jobs.size).to eq(1)
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
            expect(worker_class.jobs[0]['args']).to eq(['FooJob', [id1, id2]])
            expect(worker_class.jobs[0]['at']).to eq(10.minutes.from_now.to_f)
            expect(worker_class.jobs[1]['args']).to eq(['FooJob', [id3, id3]])
            expect(worker_class.jobs[1]['at']).to eq(20.minutes.from_now.to_f)
          end
        end

        context 'when the primary_column_name is a string' do
          it 'does not raise error' do
            expect do
              model.queue_background_migration_jobs_by_range_at_intervals(ContainerExpirationPolicy, 'FooJob', 10.minutes, primary_column_name: :name_regex)
            end.not_to raise_error
          end
        end

        context "when the primary_column_name is not an integer or a string" do
          it 'raises error' do
            expect do
              model.queue_background_migration_jobs_by_range_at_intervals(ContainerExpirationPolicy, 'FooJob', 10.minutes, primary_column_name: :enabled)
            end.to raise_error(StandardError, /is not an integer or string column/)
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

      context 'when using Migration[2.0]' do
        let(:base_class) { Class.new(Gitlab::Database::Migration[2.0]) }

        context 'when restriction is set to gitlab_shared' do
          before do
            base_class.restrict_gitlab_migration gitlab_schema: :gitlab_shared
          end

          it 'does raise an exception' do
            expect do
              model.queue_background_migration_jobs_by_range_at_intervals(ProjectAuthorization, 'FooJob', 10.seconds)
            end.to raise_error(/use `restrict_gitlab_migration:` " with `:gitlab_shared`/)
          end
        end
      end

      context 'when within transaction' do
        before do
          allow(model).to receive(:transaction_open?).and_return(true)
        end

        it 'does raise an exception' do
          expect do
            model.queue_background_migration_jobs_by_range_at_intervals(ProjectAuthorization, 'FooJob', 10.seconds)
          end.to raise_error(/The `#queue_background_migration_jobs_by_range_at_intervals` can not be run inside a transaction./)
        end
      end
    end

    describe '#requeue_background_migration_jobs_by_range_at_intervals' do
      let!(:job_class_name) { 'TestJob' }
      let!(:pending_job_1) { create(:background_migration_job, class_name: job_class_name, status: :pending, arguments: [1, 2]) }
      let!(:pending_job_2) { create(:background_migration_job, class_name: job_class_name, status: :pending, arguments: [3, 4]) }
      let!(:successful_job_1) { create(:background_migration_job, class_name: job_class_name, status: :succeeded, arguments: [5, 6]) }
      let!(:successful_job_2) { create(:background_migration_job, class_name: job_class_name, status: :succeeded, arguments: [7, 8]) }

      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

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

      context 'when using Migration[2.0]' do
        let(:base_class) { Class.new(Gitlab::Database::Migration[2.0]) }

        it 'does re-enqueue pending jobs' do
          subject

          expect(worker_class.jobs).not_to be_empty
        end

        context 'when restriction is set' do
          before do
            base_class.restrict_gitlab_migration gitlab_schema: :gitlab_main
          end

          it 'does raise an exception' do
            expect { subject }
              .to raise_error(/The `#requeue_background_migration_jobs_by_range_at_intervals` cannot use `restrict_gitlab_migration:`./)
          end
        end
      end

      context 'when within transaction' do
        before do
          allow(model).to receive(:transaction_open?).and_return(true)
        end

        it 'does raise an exception' do
          expect { subject }
            .to raise_error(/The `#requeue_background_migration_jobs_by_range_at_intervals` can not be run inside a transaction./)
        end
      end

      context 'when nothing is queued' do
        subject { model.requeue_background_migration_jobs_by_range_at_intervals('FakeJob', 10.minutes) }

        it 'returns expected duration of zero when nothing gets queued' do
          expect(subject).to eq(0)
        end
      end

      it 'queues pending jobs' do
        subject

        expect(worker_class.jobs[0]['args']).to eq([job_class_name, [1, 2]])
        expect(worker_class.jobs[0]['at']).to be_nil
        expect(worker_class.jobs[1]['args']).to eq([job_class_name, [3, 4]])
        expect(worker_class.jobs[1]['at']).to eq(10.minutes.from_now.to_f)
      end

      context 'with batch_size option' do
        subject { model.requeue_background_migration_jobs_by_range_at_intervals(job_class_name, 10.minutes, batch_size: 1) }

        it 'returns the expected duration' do
          expect(subject).to eq(20.minutes)
        end

        it 'queues pending jobs' do
          subject

          expect(worker_class.jobs[0]['args']).to eq([job_class_name, [1, 2]])
          expect(worker_class.jobs[0]['at']).to be_nil
          expect(worker_class.jobs[1]['args']).to eq([job_class_name, [3, 4]])
          expect(worker_class.jobs[1]['at']).to eq(10.minutes.from_now.to_f)
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

          expect(worker_class.jobs[0]['args']).to eq([job_class_name, [1, 2]])
          expect(worker_class.jobs[0]['at']).to eq(3.minutes.from_now.to_f)
          expect(worker_class.jobs[1]['args']).to eq([job_class_name, [3, 4]])
          expect(worker_class.jobs[1]['at']).to eq(13.minutes.from_now.to_f)
        end

        context 'when nothing is queued' do
          subject { model.requeue_background_migration_jobs_by_range_at_intervals('FakeJob', 10.minutes) }

          it 'returns expected duration of zero when nothing gets queued' do
            expect(subject).to eq(0)
          end
        end
      end
    end

    describe '#finalize_background_migration' do
      let(:coordinator) { Gitlab::BackgroundMigration::JobCoordinator.new(worker_class) }

      let!(:tracked_pending_job) { create(:background_migration_job, class_name: job_class_name, status: :pending, arguments: [1]) }
      let!(:tracked_successful_job) { create(:background_migration_job, class_name: job_class_name, status: :succeeded, arguments: [2]) }
      let!(:job_class_name) { 'TestJob' }

      let!(:job_class) do
        Class.new do
          def perform(*arguments)
            Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded('TestJob', arguments)
          end
        end
      end

      before do
        allow(Gitlab::BackgroundMigration).to receive(:coordinator_for_database)
          .with(tracking_database).and_return(coordinator)

        allow(coordinator).to receive(:migration_class_for)
          .with(job_class_name) { job_class }

        Sidekiq::Testing.disable! do
          worker_class.perform_async(job_class_name, [1, 2])
          worker_class.perform_async(job_class_name, [3, 4])
          worker_class.perform_in(10, job_class_name, [5, 6])
          worker_class.perform_in(20, job_class_name, [7, 8])
        end

        allow(model).to receive(:transaction_open?).and_return(false)
      end

      it_behaves_like 'finalized tracked background migration', worker_class do
        before do
          model.finalize_background_migration(job_class_name)
        end
      end

      context 'when within transaction' do
        before do
          allow(model).to receive(:transaction_open?).and_return(true)
        end

        it 'does raise an exception' do
          expect { model.finalize_background_migration(job_class_name, delete_tracking_jobs: %w[pending succeeded]) }
            .to raise_error(/The `#finalize_background_migration` can not be run inside a transaction./)
        end
      end

      context 'when using Migration[2.0]' do
        let(:base_class) { Class.new(Gitlab::Database::Migration[2.0]) }

        it_behaves_like 'finalized tracked background migration', worker_class do
          before do
            model.finalize_background_migration(job_class_name)
          end
        end

        context 'when restriction is set' do
          before do
            base_class.restrict_gitlab_migration gitlab_schema: :gitlab_main
          end

          it 'does raise an exception' do
            expect { model.finalize_background_migration(job_class_name, delete_tracking_jobs: %w[pending succeeded]) }
              .to raise_error(/The `#finalize_background_migration` cannot use `restrict_gitlab_migration:`./)
          end
        end
      end

      context 'when running migration in reconfigured ActiveRecord::Base context' do
        it_behaves_like 'reconfigures connection stack', tracking_database do
          it 'does restore connection hierarchy' do
            expect_next_instances_of(job_class, 1..) do |job|
              expect(job).to receive(:perform) do
                validate_connections_stack!
              end
            end

            model.finalize_background_migration(job_class_name, delete_tracking_jobs: %w[pending succeeded])
          end
        end
      end

      context 'when removing all tracked job records' do
        let!(:job_class) do
          Class.new do
            def perform(*arguments)
              # Force pending jobs to remain pending
            end
          end
        end

        before do
          model.finalize_background_migration(job_class_name, delete_tracking_jobs: %w[pending succeeded])
        end

        it_behaves_like 'finalized tracked background migration', worker_class
        it_behaves_like 'removed tracked jobs', 'pending'
        it_behaves_like 'removed tracked jobs', 'succeeded'
      end

      context 'when retaining all tracked job records' do
        before do
          model.finalize_background_migration(job_class_name, delete_tracking_jobs: false)
        end

        it_behaves_like 'finalized background migration', worker_class
        include_examples 'retained tracked jobs', 'succeeded'
      end

      context 'during retry race condition' do
        let!(:job_class) do
          Class.new do
            class << self
              attr_accessor :worker_class

              def queue_items_added
                @queue_items_added ||= []
              end
            end

            def worker_class
              self.class.worker_class
            end

            def queue_items_added
              self.class.queue_items_added
            end

            def perform(*arguments)
              Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded('TestJob', arguments)

              # Mock another process pushing queue jobs.
              if self.class.queue_items_added.count < 10
                Sidekiq::Testing.disable! do
                  queue_items_added << worker_class.perform_async('TestJob', [Time.current])
                  queue_items_added << worker_class.perform_in(10, 'TestJob', [Time.current])
                end
              end
            end
          end
        end

        it_behaves_like 'finalized tracked background migration', worker_class do
          before do
            # deliberately set the worker class on our test job since it won't be pulled from the surrounding scope
            job_class.worker_class = worker_class

            model.finalize_background_migration(job_class_name, delete_tracking_jobs: ['succeeded'])
          end
        end
      end
    end

    describe '#migrate_in' do
      it 'calls perform_in for the correct worker' do
        expect(worker_class).to receive(:perform_in).with(10.minutes, 'Class', 'Hello', 'World')

        model.migrate_in(10.minutes, 'Class', 'Hello', 'World')
      end

      it 'pushes a context with the current class name as caller_id' do
        expect(Gitlab::ApplicationContext).to receive(:with_context).with(caller_id: model.class.to_s)

        model.migrate_in(10.minutes, 'Class', 'Hello', 'World')
      end

      context 'when a specific coordinator is given' do
        let(:coordinator) { Gitlab::BackgroundMigration::JobCoordinator.for_tracking_database(tracking_database) }

        it 'uses that coordinator' do
          expect(coordinator).to receive(:perform_in).with(10.minutes, 'Class', 'Hello', 'World').and_call_original
          expect(worker_class).to receive(:perform_in).with(10.minutes, 'Class', 'Hello', 'World')

          model.migrate_in(10.minutes, 'Class', 'Hello', 'World', coordinator: coordinator)
        end
      end
    end

    describe '#delete_queued_jobs' do
      let(:job1) { double }
      let(:job2) { double }

      it 'deletes all queued jobs for the given background migration' do
        expect_next_instance_of(Gitlab::BackgroundMigration::JobCoordinator) do |coordinator|
          expect(coordinator).to receive(:steal).with('BackgroundMigrationClassName') do |&block|
            expect(block.call(job1)).to be(false)
            expect(block.call(job2)).to be(false)
          end
        end

        expect(job1).to receive(:delete)
        expect(job2).to receive(:delete)

        model.delete_queued_jobs('BackgroundMigrationClassName')
      end
    end
  end

  context 'when the migration is running against the main database' do
    it_behaves_like 'helpers that enqueue background migrations', BackgroundMigrationWorker, ActiveRecord::Base, 'main'
  end

  context 'when the migration is running against the ci database', if: Gitlab::Database.has_config?(:ci) do
    around do |example|
      Gitlab::Database::SharedModel.using_connection(::Ci::ApplicationRecord.connection) do
        example.run
      end
    end

    it_behaves_like 'helpers that enqueue background migrations', BackgroundMigration::CiDatabaseWorker, Ci::ApplicationRecord, 'ci'
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
