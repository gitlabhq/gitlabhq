# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::EventPathsConsistencyCronWorker, feature_category: :value_stream_management do
  let(:worker) { described_class.new }

  context 'when ClickHouse is disabled' do
    it 'does nothing' do
      allow(ClickHouse::Client).to receive(:database_configured?).and_return(false)

      expect(worker).not_to receive(:log_extra_metadata_on_done)

      worker.perform
    end
  end

  context 'when the event_sync_worker_for_click_house feature flag is off' do
    before do
      stub_feature_flags(event_sync_worker_for_click_house: false)
    end

    it 'does nothing' do
      allow(ClickHouse::Client).to receive(:database_configured?).and_return(true)

      expect(worker).not_to receive(:log_extra_metadata_on_done)

      worker.perform
    end
  end

  context 'when ClickHouse is available', :click_house do
    let_it_be(:connection) { ClickHouse::Connection.new(:main) }
    let_it_be_with_reload(:namespace1) { create(:group) }
    let_it_be_with_reload(:namespace2) { create(:project).project_namespace }
    let_it_be_with_reload(:namespace_with_updated_parent) { create(:group, parent: create(:group)) }

    let(:leftover_paths) { connection.select('SELECT DISTINCT path FROM events FINAL').pluck('path') }
    let(:deleted_namespace_id) { namespace_with_updated_parent.id + 1 }

    before do
      insert_query = <<~SQL
      INSERT INTO events (id, path) VALUES
      (1, '#{namespace1.id}/'),
      (2, '#{namespace2.traversal_ids.join('/')}/'),
      (3, '#{namespace1.id}/#{namespace_with_updated_parent.id}/'),
      (4, '#{deleted_namespace_id}/'),
      (5, '#{deleted_namespace_id}/')
      SQL

      connection.execute(insert_query)
    end

    it 'fixes all inconsistent records in ClickHouse' do
      worker.perform

      paths = [
        "#{namespace1.id}/",
        "#{namespace2.traversal_ids.join('/')}/",
        "#{namespace_with_updated_parent.traversal_ids.join('/')}/"
      ]

      expect(leftover_paths).to match_array(paths)

      # the next job starts from the beginning of the table
      expect(ClickHouse::SyncCursor.cursor_for(:event_namespace_paths_consistency_check)).to eq(0)
    end

    context 'when the table is empty' do
      it 'does not do anything' do
        connection.execute('TRUNCATE TABLE event_namespace_paths')

        expect { worker.perform }.not_to change { connection.select('SELECT * FROM events FINAL ORDER BY id') }
      end
    end

    context 'when the previous job was not finished' do
      it 'continues the processing from the cursor' do
        ClickHouse::SyncCursor.update_cursor_for(:event_namespace_paths_consistency_check, deleted_namespace_id)

        worker.perform

        paths = [
          "#{namespace1.id}/",
          "#{namespace2.traversal_ids.join('/')}/",
          "#{namespace1.id}/#{namespace_with_updated_parent.id}/"
        ]
        # the previous records should remain
        expect(leftover_paths).to match_array(paths)
      end
    end

    context 'when processing stops due to the record clean up limit' do
      it 'stores the last processed id value' do
        stub_const("#{described_class}::MAX_RECORD_MODIFICATIONS", 1)
        stub_const("#{ClickHouse::Concerns::ConsistencyWorker}::POSTGRESQL_BATCH_SIZE", 1)

        expect(worker).to receive(:log_extra_metadata_on_done).with(:result,
          { status: :limit_reached, modifications: 1 })

        worker.perform

        paths = [
          "#{namespace1.id}/",
          "#{namespace2.traversal_ids.join('/')}/",
          "#{namespace_with_updated_parent.traversal_ids.join('/')}/",
          "#{deleted_namespace_id}/"
        ]

        expect(leftover_paths).to match_array(paths)
        expect(ClickHouse::SyncCursor.cursor_for(:event_namespace_paths_consistency_check))
          .to eq(namespace_with_updated_parent.id)
      end
    end

    context 'when the processing stops due to time limit' do
      it 'returns over_time status' do
        stub_const("#{ClickHouse::Concerns::ConsistencyWorker}::POSTGRESQL_BATCH_SIZE", 1)

        allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |runtime_limiter|
          allow(runtime_limiter).to receive(:over_time?).and_return(false, true)
        end

        expect(worker).to receive(:log_extra_metadata_on_done).with(:result,
          { status: :over_time, modifications: 1 })

        worker.perform
      end
    end
  end
end
