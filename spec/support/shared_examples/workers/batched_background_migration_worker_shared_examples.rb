# frozen_string_literal: true

RSpec.shared_examples 'it runs batched background migration jobs' do |tracking_database|
  include ExclusiveLeaseHelpers

  describe 'defining the job attributes' do
    it 'defines the data_consistency as always' do
      expect(described_class.get_data_consistency).to eq(:always)
    end

    it 'defines the feature_category as database' do
      expect(described_class.get_feature_category).to eq(:database)
    end

    it 'defines the idempotency as true' do
      expect(described_class.idempotent?).to be_truthy
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

  describe '.lease_key' do
    let(:lease_key) { described_class.name.demodulize.underscore }

    it 'does not raise an error' do
      expect { described_class.lease_key }.not_to raise_error
    end

    it 'returns the lease key' do
      expect(described_class.lease_key).to eq(lease_key)
    end
  end

  describe '#perform' do
    subject(:worker) { described_class.new }

    context 'when the base model does not exist' do
      before do
        if Gitlab::Database.has_config?(tracking_database)
          skip "because the base model for #{tracking_database} exists"
        end
      end

      it 'does nothing' do
        expect(worker).not_to receive(:active_migration)
        expect(worker).not_to receive(:run_active_migration)

        expect { worker.perform }.not_to raise_error
      end

      it 'logs a message indicating execution is skipped' do
        expect(Sidekiq.logger).to receive(:info) do |payload|
          expect(payload[:class]).to eq(described_class.name)
          expect(payload[:database]).to eq(tracking_database)
          expect(payload[:message]).to match(/skipping migration execution/)
        end

        expect { worker.perform }.not_to raise_error
      end
    end

    context 'when the base model does exist' do
      before do
        unless Gitlab::Database.has_config?(tracking_database)
          skip "because the base model for #{tracking_database} does not exist"
        end
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(execute_batched_migrations_on_schedule: false)
        end

        it 'does nothing' do
          expect(worker).not_to receive(:active_migration)
          expect(worker).not_to receive(:run_active_migration)

          worker.perform
        end
      end

      context 'when the feature flag is enabled' do
        before do
          stub_feature_flags(execute_batched_migrations_on_schedule: true)

          allow(Gitlab::Database::BackgroundMigration::BatchedMigration).to receive(:active_migration).and_return(nil)
        end

        context 'when no active migrations exist' do
          it 'does nothing' do
            expect(worker).not_to receive(:run_active_migration)

            worker.perform
          end
        end

        context 'when active migrations exist' do
          let(:job_interval) { 5.minutes }
          let(:lease_timeout) { 15.minutes }
          let(:lease_key) { described_class.name.demodulize.underscore }
          let(:migration) { build(:batched_background_migration, :active, interval: job_interval) }
          let(:interval_variance) { described_class::INTERVAL_VARIANCE }

          before do
            allow(Gitlab::Database::BackgroundMigration::BatchedMigration).to receive(:active_migration)
              .and_return(migration)

            allow(migration).to receive(:interval_elapsed?).with(variance: interval_variance).and_return(true)
            allow(migration).to receive(:reload)
          end

          context 'when the reloaded migration is no longer active' do
            it 'does not run the migration' do
              expect_to_obtain_exclusive_lease(lease_key, timeout: lease_timeout)

              expect(migration).to receive(:reload)
              expect(migration).to receive(:active?).and_return(false)

              expect(worker).not_to receive(:run_active_migration)

              worker.perform
            end
          end

          context 'when the interval has not elapsed' do
            it 'does not run the migration' do
              expect_to_obtain_exclusive_lease(lease_key, timeout: lease_timeout)

              expect(migration).to receive(:interval_elapsed?).with(variance: interval_variance).and_return(false)

              expect(worker).not_to receive(:run_active_migration)

              worker.perform
            end
          end

          context 'when the reloaded migration is still active and the interval has elapsed' do
            it 'runs the migration' do
              expect_to_obtain_exclusive_lease(lease_key, timeout: lease_timeout)

              expect_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |instance|
                expect(instance).to receive(:run_migration_job).with(migration)
              end

              expect(worker).to receive(:run_active_migration).and_call_original

              worker.perform
            end
          end

          context 'when the calculated timeout is less than the minimum allowed' do
            let(:minimum_timeout) { described_class::MINIMUM_LEASE_TIMEOUT }
            let(:job_interval) { 2.minutes }

            it 'sets the lease timeout to the minimum value' do
              expect_to_obtain_exclusive_lease(lease_key, timeout: minimum_timeout)

              expect_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |instance|
                expect(instance).to receive(:run_migration_job).with(migration)
              end

              expect(worker).to receive(:run_active_migration).and_call_original

              worker.perform
            end
          end

          it 'always cleans up the exclusive lease' do
            lease = stub_exclusive_lease_taken(lease_key, timeout: lease_timeout)

            expect(lease).to receive(:try_obtain).and_return(true)

            expect(worker).to receive(:run_active_migration).and_raise(RuntimeError, 'I broke')
            expect(lease).to receive(:cancel)

            expect { worker.perform }.to raise_error(RuntimeError, 'I broke')
          end

          it 'receives the correct connection' do
            base_model = Gitlab::Database.database_base_models[tracking_database]

            expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(base_model.connection).and_yield

            worker.perform
          end
        end
      end
    end
  end
end
