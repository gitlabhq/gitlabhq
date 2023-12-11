# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::EventsSyncWorker, feature_category: :value_stream_management do
  let(:worker) { described_class.new }

  specify do
    expect(worker.class.click_house_worker_attrs).to match(
      a_hash_including(migration_lock_ttl: ClickHouse::MigrationSupport::ExclusiveLock::DEFAULT_CLICKHOUSE_WORKER_TTL)
    )
  end

  it_behaves_like 'an idempotent worker' do
    context 'when the event_sync_worker_for_click_house feature flag is on', :click_house do
      before do
        stub_feature_flags(event_sync_worker_for_click_house: true)
      end

      context 'when there is nothing to sync' do
        it 'adds metadata for the worker' do
          expect(worker).to receive(:log_extra_metadata_on_done).with(:result,
            { status: :processed, records_inserted: 0, reached_end_of_table: true })

          worker.perform

          events = ClickHouse::Client.select('SELECT * FROM events', :main)
          expect(events).to be_empty
        end
      end

      context 'when syncing records' do
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, group: group) }
        let_it_be(:issue) { create(:issue, project: project) }
        let_it_be(:project_event2) { create(:event, :closed, project: project, target: issue) }
        let_it_be(:event_without_parent) { create(:event, :joined, project: nil, group: nil) }
        let_it_be(:group_event) { create(:event, :created, group: group, project: nil) }
        let_it_be(:project_event1) { create(:event, :created, project: project, target: issue) }
        # looks invalid but we have some records like this on PRD

        it 'inserts all records' do
          expect(worker).to receive(:log_extra_metadata_on_done).with(:result,
            { status: :processed, records_inserted: 4, reached_end_of_table: true })

          worker.perform

          expected_records = [
            hash_including('id' => project_event2.id, 'path' => "#{group.id}/#{project.project_namespace.id}/",
              'target_type' => 'Issue'),
            hash_including('id' => event_without_parent.id, 'path' => '', 'target_type' => ''),
            hash_including('id' => group_event.id, 'path' => "#{group.id}/", 'target_type' => ''),
            hash_including('id' => project_event1.id, 'path' => "#{group.id}/#{project.project_namespace.id}/",
              'target_type' => 'Issue')
          ]

          events = ClickHouse::Client.select('SELECT * FROM events ORDER BY id', :main)

          expect(events).to match(expected_records)

          last_processed_id = ClickHouse::SyncCursor.cursor_for(:events)
          expect(last_processed_id).to eq(project_event1.id)
        end

        context 'when multiple batches are needed' do
          before do
            stub_const("#{described_class}::BATCH_SIZE", 1)
            stub_const("#{described_class}::INSERT_BATCH_SIZE", 1)
          end

          it 'inserts all records' do
            expect(worker).to receive(:log_extra_metadata_on_done).with(:result,
              { status: :processed, records_inserted: 4, reached_end_of_table: true })

            worker.perform

            events = ClickHouse::Client.select('SELECT * FROM events', :main)
            expect(events.size).to eq(4)
          end

          context 'when new records are inserted while processing' do
            it 'does not process new records created during the iteration' do
              expect(worker).to receive(:log_extra_metadata_on_done).with(:result,
                { status: :processed, records_inserted: 4,
                  reached_end_of_table: true })

              # Simulating the case when there is an insert during the iteration
              call_count = 0
              allow(worker).to receive(:next_batch).and_wrap_original do |method|
                call_count += 1
                create(:event) if call_count == 3
                method.call
              end

              worker.perform
            end
          end
        end

        context 'when time limit is reached' do
          before do
            stub_const("#{described_class}::BATCH_SIZE", 1)
          end

          it 'stops the processing' do
            allow_next_instance_of(Analytics::CycleAnalytics::RuntimeLimiter) do |runtime_limiter|
              allow(runtime_limiter).to receive(:over_time?).and_return(false, true)
            end

            expect(worker).to receive(:log_extra_metadata_on_done).with(:result,
              { status: :processed, records_inserted: 2, reached_end_of_table: false })

            worker.perform

            last_processed_id = ClickHouse::SyncCursor.cursor_for(:events)
            expect(last_processed_id).to eq(event_without_parent.id)
          end
        end

        context 'when syncing from a certain point' do
          before do
            ClickHouse::SyncCursor.update_cursor_for(:events, project_event2.id)
          end

          it 'syncs records after the cursor' do
            expect(worker).to receive(:log_extra_metadata_on_done).with(:result,
              { status: :processed, records_inserted: 3, reached_end_of_table: true })

            worker.perform

            events = ClickHouse::Client.select('SELECT id FROM events ORDER BY id', :main)
            expect(events).to eq([{ 'id' => event_without_parent.id }, { 'id' => group_event.id },
              { 'id' => project_event1.id }])
          end

          context 'when there is nothing to sync' do
            it 'does nothing' do
              expect(worker).to receive(:log_extra_metadata_on_done).with(:result,
                { status: :processed, records_inserted: 0, reached_end_of_table: true })

              ClickHouse::SyncCursor.update_cursor_for(:events, project_event1.id)
              worker.perform

              events = ClickHouse::Client.select('SELECT id FROM events ORDER BY id', :main)
              expect(events).to be_empty
            end
          end
        end
      end
    end

    context 'when clickhouse is not configured' do
      before do
        allow(ClickHouse::Client.configuration).to receive(:databases).and_return({})
      end

      it 'skips execution' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:result, { status: :disabled })

        worker.perform
      end
    end
  end

  context 'when exclusive lease error happens' do
    it 'skips execution' do
      stub_feature_flags(event_sync_worker_for_click_house: true)
      allow(ClickHouse::Client.configuration).to receive(:databases).and_return({ main: :some_db })

      expect(worker).to receive(:in_lock).and_raise(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:result, { status: :skipped })

      worker.perform
    end
  end

  context 'when the event_sync_worker_for_click_house feature flag is off' do
    before do
      stub_feature_flags(event_sync_worker_for_click_house: false)
    end

    it 'skips execution' do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:result, { status: :disabled })

      worker.perform
    end
  end
end
