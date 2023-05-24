# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::MonitorLockedTablesWorker, feature_category: :cell do
  let(:worker) { described_class.new }
  let(:tables_locker) { instance_double(Gitlab::Database::TablesLocker, lock_writes: nil) }

  describe '#perform' do
    context 'when running with single database' do
      before do
        skip_if_database_exists(:ci)
      end

      it 'skips executing the job' do
        expect(Gitlab::Database::TablesLocker).not_to receive(:new)
        worker.perform
      end
    end

    context 'when running in decomposed database' do
      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(monitor_database_locked_tables: false)
        end

        it 'skips executing the job' do
          expect(Gitlab::Database::TablesLocker).not_to receive(:new)
          worker.perform
        end
      end

      context 'when the feature flag is enabled' do
        before do
          skip_if_shared_database(:ci)
          stub_feature_flags(monitor_database_locked_tables: true)
          allow(Gitlab::Database::TablesLocker).to receive(:new).and_return(tables_locker)
        end

        it 'calls TablesLocker with dry_run enabled' do
          expect(tables_locker).to receive(:lock_writes).and_return([])
          expect(worker).to receive(:log_extra_metadata_on_done)

          worker.perform
        end

        it 'reports the tables that need to be locked on both databases main and ci' do
          lock_writes_results = [
            { table: 'users', database: 'ci', action: 'needs_lock' },
            { table: 'projects', database: 'ci', action: 'needs_lock' },
            { table: 'ci_builds', database: 'ci', action: 'skipped' },
            { table: 'ci_builds', database: 'main', action: 'needs_lock' },
            { table: 'users', database: 'main', action: 'skipped' },
            { table: 'projects', database: 'main', action: 'skipped' },
            { table: 'issues', database: 'main', action: 'needs_unlock' } # if a table was locked by mistake
          ]
          expected_log_results = {
            'ci' => {
              tables_need_lock: %w[users projects],
              tables_need_lock_count: 2,
              tables_need_unlock: [],
              tables_need_unlock_count: 0
            },
            'main' => {
              tables_need_lock: ['ci_builds'],
              tables_need_lock_count: 1,
              tables_need_unlock: ['issues'],
              tables_need_unlock_count: 1
            }
          }
          expect(tables_locker).to receive(:lock_writes).and_return(lock_writes_results)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:results, expected_log_results)

          worker.perform
        end
      end
    end
  end
end
