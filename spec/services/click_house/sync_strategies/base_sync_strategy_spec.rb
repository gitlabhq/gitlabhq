# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::SyncStrategies::BaseSyncStrategy, feature_category: :value_stream_management do
  let(:strategy) { described_class.new }

  describe '#execute' do
    subject(:execute) { strategy.execute }

    context 'when clickhouse configuration database is available', :click_house do
      before do
        allow(strategy).to receive(:model_class).and_return(::Event)
        allow(strategy).to receive(:projections).and_return([:id])
        allow(strategy).to receive(:csv_mapping).and_return({ id: :id })
        allow(strategy).to receive(:insert_query).and_return("INSERT INTO events (id) SETTINGS async_insert=1,
                                                            wait_for_async_insert=1 FORMAT CSV")
      end

      context 'when there is nothing to sync' do
        it 'adds metadata for the worker' do
          expect(execute).to eq({ status: :processed, records_inserted: 0, reached_end_of_table: true })

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

        it 'inserts all records' do
          expect(execute).to eq({ status: :processed, records_inserted: 4, reached_end_of_table: true })

          expected_records = [
            hash_including('id' => project_event2.id),
            hash_including('id' => event_without_parent.id),
            hash_including('id' => group_event.id),
            hash_including('id' => project_event1.id)
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
            expect(execute).to eq({ status: :processed, records_inserted: 4, reached_end_of_table: true })

            events = ClickHouse::Client.select('SELECT * FROM events', :main)
            expect(events.size).to eq(4)
          end

          context 'when new records are inserted while processing' do
            it 'does not process new records created during the iteration' do
              # Simulating the case when there is an insert during the iteration
              call_count = 0
              allow(strategy).to receive(:next_batch).and_wrap_original do |method|
                call_count += 1
                create(:event) if call_count == 3
                method.call
              end

              expect(execute).to eq({ status: :processed, records_inserted: 4, reached_end_of_table: true })
            end
          end
        end

        context 'when time limit is reached' do
          before do
            stub_const("#{described_class}::BATCH_SIZE", 1)
          end

          it 'stops the processing' do
            allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |runtime_limiter|
              allow(runtime_limiter).to receive(:over_time?).and_return(false, true)
            end

            expect(execute).to eq({ status: :processed, records_inserted: 2, reached_end_of_table: false })

            last_processed_id = ClickHouse::SyncCursor.cursor_for(:events)
            expect(last_processed_id).to eq(event_without_parent.id)
          end
        end

        context 'when syncing from a certain point' do
          before do
            ClickHouse::SyncCursor.update_cursor_for(:events, project_event2.id)
          end

          it 'syncs records after the cursor' do
            expect(execute).to eq({ status: :processed, records_inserted: 3, reached_end_of_table: true })

            events = ClickHouse::Client.select('SELECT id FROM events ORDER BY id', :main)

            expect(events).to eq([{ 'id' => event_without_parent.id }, { 'id' => group_event.id },
              { 'id' => project_event1.id }])
          end

          context 'when there is nothing to sync' do
            it 'does nothing' do
              ClickHouse::SyncCursor.update_cursor_for(:events, project_event1.id)

              expect(execute).to eq({ status: :processed, records_inserted: 0, reached_end_of_table: true })

              events = ClickHouse::Client.select('SELECT id FROM events ORDER BY id', :main)
              expect(events).to be_empty
            end
          end
        end
      end
    end

    context 'when clickhouse is not configured' do
      before do
        allow(Gitlab::ClickHouse).to receive(:configured?).and_return(false)
      end

      it 'skips execution' do
        expect(execute).to eq({ status: :disabled })
      end
    end

    context 'when exclusive lease error happens' do
      it 'skips execution' do
        allow(Gitlab::ClickHouse).to receive(:configured?).and_return(true)

        expect(strategy).to receive(:in_lock).and_raise(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
        expect(execute).to eq({ status: :skipped })
      end
    end
  end

  describe '#projections' do
    it 'raises a NotImplementedError' do
      expect { strategy.send(:projections) }.to raise_error(NotImplementedError,
        "Subclasses must implement `projections`")
    end
  end

  describe '#csv_mapping' do
    it 'raises a NotImplementedError' do
      expect { strategy.send(:csv_mapping) }.to raise_error(NotImplementedError,
        "Subclasses must implement `csv_mapping`")
    end
  end

  describe '#insert_query' do
    it 'raises a NotImplementedError' do
      expect { strategy.send(:insert_query) }.to raise_error(NotImplementedError,
        "Subclasses must implement `insert_query`")
    end
  end
end
