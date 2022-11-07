# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BatchedBackgroundMigration::ExecutionWorker, :clean_gitlab_redis_shared_state do
  describe '#perform' do
    let(:database_name) { Gitlab::Database::MAIN_DATABASE_NAME.to_sym }

    subject(:worker) { described_class.new }

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(execute_batched_migrations_on_schedule: false)
      end

      it 'does nothing' do
        expect(worker).not_to receive(:run)

        worker.perform(database_name, 123)
      end
    end

    context 'when the feature flag is enabled' do
      before do
        stub_feature_flags(execute_batched_migrations_on_schedule: true)
      end

      context 'when migration does not exist' do
        it 'does nothing' do
          expect(worker).not_to receive(:run)

          worker.perform(database_name, non_existing_record_id)
        end
      end

      context 'when migration exist' do
        let(:base_model) { Gitlab::Database.database_base_models[database_name] }
        let(:table_name) { :events }
        let(:job_interval) { 5.minutes }
        let(:interval_variance) { described_class::INTERVAL_VARIANCE }
        let(:migration) do
          create(:batched_background_migration, :active, interval: job_interval, table_name: table_name)
        end

        before do
          allow(Gitlab::Database::BackgroundMigration::BatchedMigration).to receive(:find_executable)
            .with(migration.id, connection: base_model.connection)
            .and_return(migration)
        end

        context 'when the migration is no longer active' do
          it 'does not run the migration' do
            expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(base_model.connection).and_yield

            expect(migration).to receive(:active?).and_return(false)

            expect(worker).not_to receive(:run)

            worker.perform(database_name, migration.id)
          end
        end

        context 'when the interval has not elapsed' do
          it 'does not run the migration' do
            expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(base_model.connection).and_yield

            expect(migration).to receive(:interval_elapsed?).with(variance: interval_variance).and_return(false)

            expect(worker).not_to receive(:run)

            worker.perform(database_name, migration.id)
          end
        end

        context 'when the migration is still active and the interval has elapsed' do
          it 'runs the migration' do
            expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(base_model.connection).and_yield

            expect_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |instance|
              expect(instance).to receive(:run_migration_job).with(migration)
            end

            expect(worker).to receive(:run).and_call_original

            worker.perform(database_name, migration.id)
          end
        end
      end
    end
  end
end
