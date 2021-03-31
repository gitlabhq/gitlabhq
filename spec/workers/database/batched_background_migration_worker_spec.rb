# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BatchedBackgroundMigrationWorker, '#perform', :clean_gitlab_redis_shared_state do
  include ExclusiveLeaseHelpers

  let(:worker) { described_class.new }

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
      let(:lease_key) { 'batched_background_migration_worker' }
      let(:migration) { build(:batched_background_migration, :active, interval: 2.minutes) }

      before do
        allow(Gitlab::Database::BackgroundMigration::BatchedMigration).to receive(:active_migration)
          .and_return(migration)

        allow(migration).to receive(:interval_elapsed?).and_return(true)
        allow(migration).to receive(:reload)
      end

      context 'when the reloaded migration is no longer active' do
        it 'does not run the migration' do
          expect_to_obtain_exclusive_lease(lease_key, timeout: 4.minutes)

          expect(migration).to receive(:reload)
          expect(migration).to receive(:active?).and_return(false)

          expect(worker).not_to receive(:run_active_migration)

          worker.perform
        end
      end

      context 'when the interval has not elapsed' do
        it 'does not run the migration' do
          expect_to_obtain_exclusive_lease(lease_key, timeout: 4.minutes)

          expect(migration).to receive(:interval_elapsed?).and_return(false)

          expect(worker).not_to receive(:run_active_migration)

          worker.perform
        end
      end

      context 'when the reloaded migration is still active and the interval has elapsed' do
        it 'runs the migration' do
          expect_to_obtain_exclusive_lease(lease_key, timeout: 4.minutes)

          expect_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |instance|
            expect(instance).to receive(:run_migration_job).with(migration)
          end

          expect(worker).to receive(:run_active_migration).and_call_original

          worker.perform
        end
      end

      it 'always cleans up the exclusive lease' do
        lease = stub_exclusive_lease_taken(lease_key, timeout: 4.minutes)

        expect(lease).to receive(:try_obtain).and_return(true)

        expect(worker).to receive(:run_active_migration).and_raise(RuntimeError, 'I broke')
        expect(lease).to receive(:cancel)

        expect { worker.perform }.to raise_error(RuntimeError, 'I broke')
      end
    end
  end
end
