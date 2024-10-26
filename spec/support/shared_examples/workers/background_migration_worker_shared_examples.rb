# frozen_string_literal: true

RSpec.shared_examples 'it runs background migration jobs' do |tracking_database|
  before do
    stub_feature_flags(disallow_database_ddl_feature_flags: false)
  end

  describe 'defining the job attributes' do
    it 'defines the data_consistency as always' do
      expect(described_class.get_data_consistency_per_database.values.uniq).to eq([:always])
    end

    it 'defines the retry count in sidekiq_options' do
      expect(described_class.sidekiq_options['retry']).to eq(3)
    end

    it 'defines the feature_category as database' do
      expect(described_class.get_feature_category).to eq(:database)
    end

    it 'defines the urgency as throttled' do
      expect(described_class.get_urgency).to eq(:throttled)
    end

    it 'defines the loggable_arguments' do
      expect(described_class.loggable_arguments).to match_array([0, 1])
    end
  end

  describe '.tracking_database' do
    it 'does not raise an error' do
      expect { described_class.tracking_database }.not_to raise_error
    end

    it 'overrides the method to return the tracking database' do
      expect(described_class.tracking_database).to eq(tracking_database)
    end
  end

  describe '.minimum_interval' do
    it 'returns 2 minutes' do
      expect(described_class.minimum_interval).to eq(2.minutes.to_i)
    end
  end

  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when execute_background_migrations feature flag is disabled' do
      before do
        stub_feature_flags(execute_background_migrations: false)
      end

      it 'does not perform the job, reschedules it in the future, and logs a message' do
        expect(worker).not_to receive(:perform_with_connection)

        expect(Sidekiq.logger).to receive(:info) do |payload|
          expect(payload[:class]).to eq(described_class.name)
          expect(payload[:database]).to eq(tracking_database)
          expect(payload[:message]).to match(/skipping execution, migration rescheduled/)
        end

        lease_attempts = 3
        delay = described_class::BACKGROUND_MIGRATIONS_DELAY
        job_args = [10, 20]

        freeze_time do
          worker.perform('Foo', job_args, lease_attempts)

          job = described_class.jobs.find { |job| job['args'] == ['Foo', job_args, lease_attempts] }
          expect(job).to be, "Expected the job to be rescheduled with (#{job_args}, #{lease_attempts}), but it was not."

          expected_time = delay.to_i + Time.now.to_i
          expect(job['at']).to eq(expected_time),
            "Expected the job to be rescheduled in #{expected_time} seconds, " \
            "but it was rescheduled in #{job['at']} seconds."
        end
      end
    end

    context 'when disallow_database_ddl_feature_flags feature flag is disabled' do
      before do
        stub_feature_flags(disallow_database_ddl_feature_flags: true)
      end

      it 'does not perform the job, reschedules it in the future, and logs a message' do
        expect(worker).not_to receive(:perform_with_connection)

        expect(Sidekiq.logger).to receive(:info) do |payload|
          expect(payload[:class]).to eq(described_class.name)
          expect(payload[:database]).to eq(tracking_database)
          expect(payload[:message]).to match(/skipping execution, migration rescheduled/)
        end

        lease_attempts = 3
        delay = described_class::BACKGROUND_MIGRATIONS_DELAY
        job_args = [10, 20]

        freeze_time do
          worker.perform('Foo', job_args, lease_attempts)

          job = described_class.jobs.find { |job| job['args'] == ['Foo', job_args, lease_attempts] }
          expect(job).to be, "Expected the job to be rescheduled with (#{job_args}, #{lease_attempts}), but it was not."

          expected_time = delay.to_i + Time.now.to_i
          expect(job['at']).to eq(expected_time),
            "Expected the job to be rescheduled in #{expected_time} seconds, " \
            "but it was rescheduled in #{job['at']} seconds."
        end
      end
    end

    context 'when execute_background_migrations feature flag is enabled' do
      before do
        stub_feature_flags(execute_background_migrations: true)

        allow(worker).to receive(:jid).and_return(1)
        allow(worker).to receive(:always_perform?).and_return(false)

        allow(Postgresql::ReplicationSlot).to receive(:lag_too_great?).and_return(false)
      end

      it 'performs jobs using the coordinator for the worker' do
        expect_next_instance_of(Gitlab::BackgroundMigration::JobCoordinator) do |coordinator|
          allow(coordinator).to receive(:with_shared_connection).and_yield

          expect(coordinator.worker_class).to eq(described_class)
          expect(coordinator).to receive(:perform).with('Foo', [10, 20])
        end

        worker.perform('Foo', [10, 20])
      end

      context 'when lease can be obtained' do
        let(:coordinator) { double('job coordinator') }

        before do
          allow(Gitlab::BackgroundMigration).to receive(:coordinator_for_database)
            .with(tracking_database)
            .and_return(coordinator)

          allow(coordinator).to receive(:with_shared_connection).and_yield
        end

        it 'sets up the shared connection before checking replication' do
          expect(coordinator).to receive(:with_shared_connection).and_yield.ordered
          expect(Postgresql::ReplicationSlot).to receive(:lag_too_great?).and_return(false).ordered

          expect(coordinator).to receive(:perform).with('Foo', [10, 20])

          worker.perform('Foo', [10, 20])
        end

        it 'performs a background migration' do
          expect(coordinator).to receive(:perform).with('Foo', [10, 20])

          worker.perform('Foo', [10, 20])
        end

        context 'when lease_attempts is 1' do
          it 'performs a background migration' do
            expect(coordinator).to receive(:perform).with('Foo', [10, 20])

            worker.perform('Foo', [10, 20], 1)
          end
        end

        it 'can run scheduled job and retried job concurrently' do
          expect(coordinator)
            .to receive(:perform)
            .with('Foo', [10, 20])
            .exactly(2).time

          worker.perform('Foo', [10, 20])
          worker.perform('Foo', [10, 20], described_class::MAX_LEASE_ATTEMPTS - 1)
        end

        it 'sets the class that will be executed as the caller_id' do
          expect(coordinator).to receive(:perform) do
            expect(Gitlab::ApplicationContext.current).to include('meta.caller_id' => 'Foo')
          end

          worker.perform('Foo', [10, 20])
        end
      end

      context 'when lease not obtained (migration of same class was performed recently)' do
        let(:timeout) { described_class.minimum_interval }
        let(:lease_key) { "#{described_class.name}:Foo" }
        let(:coordinator) { double('job coordinator') }

        before do
          allow(Gitlab::BackgroundMigration).to receive(:coordinator_for_database)
            .with(tracking_database)
            .and_return(coordinator)

          allow(coordinator).to receive(:with_shared_connection).and_yield

          expect(coordinator).not_to receive(:perform)

          Gitlab::ExclusiveLease.new(lease_key, timeout: timeout).try_obtain
        end

        it 'reschedules the migration and decrements the lease_attempts' do
          expect(described_class)
            .to receive(:perform_in)
            .with(a_kind_of(Numeric), 'Foo', [10, 20], 4)

          worker.perform('Foo', [10, 20], 5)
        end

        context 'when lease_attempts is 1' do
          let(:lease_key) { "#{described_class.name}:Foo:retried" }

          it 'reschedules the migration and decrements the lease_attempts' do
            expect(described_class)
              .to receive(:perform_in)
              .with(a_kind_of(Numeric), 'Foo', [10, 20], 0)

            worker.perform('Foo', [10, 20], 1)
          end
        end

        context 'when lease_attempts is 0' do
          let(:lease_key) { "#{described_class.name}:Foo:retried" }

          it 'gives up performing the migration' do
            expect(described_class).not_to receive(:perform_in)
            expect(Sidekiq.logger).to receive(:warn).with(
              class: 'Foo',
              message: 'Job could not get an exclusive lease after several tries. Giving up.',
              job_id: 1)

            worker.perform('Foo', [10, 20], 0)
          end
        end
      end

      context 'when database is not healthy' do
        before do
          expect(Postgresql::ReplicationSlot).to receive(:lag_too_great?).and_return(true)
        end

        it 'reschedules a migration if the database is not healthy' do
          expect(described_class)
            .to receive(:perform_in)
            .with(a_kind_of(Numeric), 'Foo', [10, 20], 4)

          worker.perform('Foo', [10, 20])
        end

        it 'increments the unhealthy counter' do
          counter = Gitlab::Metrics.counter(:background_migration_database_health_reschedules, 'msg')

          expect(described_class).to receive(:perform_in)

          expect { worker.perform('Foo', [10, 20]) }.to change { counter.get(db_config_name: tracking_database) }.by(1)
        end

        context 'when lease_attempts is 0' do
          it 'gives up performing the migration' do
            expect(described_class).not_to receive(:perform_in)
            expect(Sidekiq.logger).to receive(:warn).with(
              class: 'Foo',
              message: 'Database was unhealthy after several tries. Giving up.',
              job_id: 1)

            worker.perform('Foo', [10, 20], 0)
          end
        end
      end
    end
  end
end
