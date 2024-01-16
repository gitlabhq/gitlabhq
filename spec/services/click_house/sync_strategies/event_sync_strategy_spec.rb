# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::SyncStrategies::EventSyncStrategy, feature_category: :value_stream_management do
  let(:strategy) { described_class.new }

  describe '#execute' do
    subject(:execute) { strategy.execute }

    context 'when syncing records', :click_house do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, group: group) }
      let_it_be(:issue) { create(:issue, project: project) }
      let_it_be(:project_event2) { create(:event, :closed, project: project, target: issue) }
      let_it_be(:event_without_parent) { create(:event, :joined, project: nil, group: nil) }
      let_it_be(:group_event) { create(:event, :created, group: group, project: nil) }
      let_it_be(:project_event1) { create(:event, :created, project: project, target: issue) }
      # looks invalid but we have some records like this on PRD

      it 'correctly inserts all records' do
        expect(execute).to eq({ status: :processed, records_inserted: 4, reached_end_of_table: true })

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
    end
  end

  describe '#projections' do
    it 'returns correct projections' do
      expect(strategy.send(:projections)).to match_array([
        :id,
        described_class::PATH_COLUMN,
        :author_id,
        :target_id,
        :target_type,
        'action AS raw_action',
        'EXTRACT(epoch FROM created_at) AS casted_created_at',
        'EXTRACT(epoch FROM updated_at) AS casted_updated_at'
      ])
    end
  end

  describe '#csv_mapping' do
    it 'returns correct csv mapping' do
      expect(strategy.send(:csv_mapping)).to eq({
        id: :id,
        path: :path,
        author_id: :author_id,
        target_id: :target_id,
        target_type: :target_type,
        action: :raw_action,
        created_at: :casted_created_at,
        updated_at: :casted_updated_at
      })
    end
  end

  describe '#insert_query' do
    let(:expected_query) do
      <<~SQL.squish
        INSERT INTO events (id, path, author_id,
                    target_id, target_type,
                    action, created_at, updated_at)
                    SETTINGS async_insert=1,
                    wait_for_async_insert=1 FORMAT CSV
      SQL
    end

    it 'returns correct insert query' do
      expect(strategy.send(:insert_query)).to eq(expected_query)
    end
  end

  describe '#model_class' do
    it 'returns the correct model class' do
      expect(strategy.send(:model_class)).to eq(::Event)
    end
  end

  describe '#enabled?' do
    context 'when the clickhouse database is configured the feature flag is enabled' do
      before do
        allow(ClickHouse::Client.configuration).to receive(:databases).and_return({ main: :some_db })
        stub_feature_flags(event_sync_worker_for_click_house: true)
      end

      it 'returns true' do
        expect(strategy.send(:enabled?)).to be_truthy
      end
    end

    context 'when the clickhouse database is not configured' do
      before do
        allow(ClickHouse::Client.configuration).to receive(:databases).and_return({})
      end

      it 'returns false' do
        expect(strategy.send(:enabled?)).to be_falsey
      end
    end

    context 'when the feature flag is disabled' do
      before do
        allow(ClickHouse::Client.configuration).to receive(:databases).and_return({ main: :some_db })
        stub_feature_flags(event_sync_worker_for_click_house: false)
      end

      it 'returns false' do
        expect(strategy.send(:enabled?)).to be_falsey
      end
    end
  end
end
