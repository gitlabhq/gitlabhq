# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::MonitorLockedTablesWorker, feature_category: :cell do
  let(:worker) { described_class.new }
  let(:tables_locker) { instance_double(Gitlab::Database::TablesLocker, lock_writes: nil) }

  describe '#perform' do
    context 'when running with single database' do
      before do
        skip_if_database_exists(:ci)
        skip_if_database_exists(:sec)
      end

      it 'skips executing the job' do
        expect(Gitlab::Database::TablesLocker).not_to receive(:new)
        worker.perform
      end
    end

    context 'when running in decomposed database' do
      before do
        skip_if_shared_database(:ci)
      end

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
          stub_feature_flags(monitor_database_locked_tables: true)
          allow(Gitlab::Database::TablesLocker).to receive(:new).and_return(tables_locker)
        end

        it 'calls TablesLocker with dry_run enabled' do
          expect(tables_locker).to receive(:lock_writes).and_return([])
          expect(worker).to receive(:log_extra_metadata_on_done)

          worker.perform
        end

        it 'reports the tables that need to be locked on both databases main and ci' do
          skip_if_database_exists(:sec)

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

        it 'reports the tables that need to be locked on main, ci, and sec databases' do
          skip_if_shared_database(:ci)
          skip_if_shared_database(:sec)

          lock_writes_results = [
            { table: 'vulnerabilities', database: 'sec', action: 'skipped' },
            { table: 'vulnerabilities', database: 'ci', action: 'needs_lock' },
            { table: 'vulnerabilities', database: 'main', action: 'needs_lock' },
            { table: 'users', database: 'sec', action: 'needs_lock' },
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
              tables_need_lock: %w[vulnerabilities users projects],
              tables_need_lock_count: 3,
              tables_need_unlock: [],
              tables_need_unlock_count: 0
            },
            'sec' => {
              tables_need_lock: %w[users],
              tables_need_lock_count: 1,
              tables_need_unlock: [],
              tables_need_unlock_count: 0
            },
            'main' => {
              tables_need_lock: %w[vulnerabilities ci_builds],
              tables_need_lock_count: 2,
              tables_need_unlock: ['issues'],
              tables_need_unlock_count: 1
            }
          }
          expect(tables_locker).to receive(:lock_writes).and_return(lock_writes_results)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:results, expected_log_results)

          worker.perform
        end

        context 'with automatically locking the unlocked tables' do
          context 'when there are no tables to be locked' do
            before do
              stub_feature_flags(lock_tables_in_monitoring: true)
              allow(tables_locker).to receive(:lock_writes).and_return([])
            end

            it 'does not call the Database::LockTablesWorker' do
              expect(Database::LockTablesWorker).not_to receive(:perform_async)
            end
          end

          context 'when there are tables to be locked' do
            before do
              lock_writes_results = [
                { table: 'users', database: 'ci', action: 'needs_lock' },
                { table: 'projects', database: 'ci', action: 'needs_lock' },
                { table: 'ci_builds', database: 'main', action: 'needs_lock' },
                { table: 'ci_pipelines', database: 'main', action: 'skipped' }
              ]
              allow(tables_locker).to receive(:lock_writes).and_return(lock_writes_results)
            end

            context 'when feature flag lock_tables_in_monitoring is enabled' do
              before do
                stub_feature_flags(lock_tables_in_monitoring: true)
              end

              it 'locks the tables that need to be locked' do
                expect(Database::LockTablesWorker).to receive(:perform_async).once.with('ci', %w[users projects])
                expect(Database::LockTablesWorker).to receive(:perform_async).once.with('main', %w[ci_builds])

                worker.perform
              end
            end

            context 'when feature flag lock_tables_in_monitoring is disabled' do
              before do
                stub_feature_flags(lock_tables_in_monitoring: false)
              end

              it 'does not lock the tables that need to be locked' do
                expect(Database::LockTablesWorker).not_to receive(:perform_async)

                worker.perform
              end
            end
          end
        end
      end
    end
  end
end
