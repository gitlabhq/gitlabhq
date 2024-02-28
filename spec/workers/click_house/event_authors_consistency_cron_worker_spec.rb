# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::EventAuthorsConsistencyCronWorker, feature_category: :value_stream_management do
  let(:worker) { described_class.new }

  context 'when ClickHouse is disabled' do
    it 'does nothing' do
      allow(Gitlab::ClickHouse).to receive(:configured?).and_return(false)

      expect(worker).not_to receive(:log_extra_metadata_on_done)

      worker.perform
    end
  end

  context 'when the event_sync_worker_for_click_house feature flag is off' do
    it 'does nothing' do
      allow(Gitlab::ClickHouse).to receive(:configured?).and_return(true)
      stub_feature_flags(event_sync_worker_for_click_house: false)

      expect(worker).not_to receive(:log_extra_metadata_on_done)

      worker.perform
    end
  end

  context 'when ClickHouse is available', :click_house do
    let_it_be(:connection) { ClickHouse::Connection.new(:main) }
    let_it_be_with_reload(:user1) { create(:user) }
    let_it_be_with_reload(:user2) { create(:user) }

    let(:leftover_author_ids) { connection.select('SELECT DISTINCT author_id FROM events FINAL').pluck('author_id') }
    let(:deleted_user_id1) { user2.id + 1 }
    let(:deleted_user_id2) { user2.id + 2 }

    before do
      insert_query = <<~SQL
      INSERT INTO events (id, author_id) VALUES
      (1, #{user1.id}),
      (2, #{user2.id}),
      (3, #{deleted_user_id1}),
      (4, #{deleted_user_id1}),
      (5, #{deleted_user_id2})
      SQL

      connection.execute(insert_query)
    end

    it 'cleans up all inconsistent records in ClickHouse' do
      worker.perform

      expect(leftover_author_ids).to contain_exactly(user1.id, user2.id)

      # the next job starts from the beginning of the table
      expect(ClickHouse::SyncCursor.cursor_for(:event_authors_consistency_check)).to eq(0)
    end

    context 'when the previous job was not finished' do
      it 'continues the processing from the cursor' do
        ClickHouse::SyncCursor.update_cursor_for(:event_authors_consistency_check, deleted_user_id2)

        worker.perform

        # the previous records should remain
        expect(leftover_author_ids).to contain_exactly(user1.id, user2.id, deleted_user_id1)
      end
    end

    context 'when processing stops due to the record clean up limit' do
      it 'stores the last processed id value' do
        User.where(id: [user1.id, user2.id]).delete_all

        stub_const("#{described_class}::MAX_AUTHOR_DELETIONS", 2)
        stub_const("#{ClickHouse::Concerns::ConsistencyWorker}::POSTGRESQL_BATCH_SIZE", 1)

        expect(worker).to receive(:log_extra_metadata_on_done).with(:result,
          { status: :limit_reached, modifications: 2 })

        worker.perform

        expect(leftover_author_ids).to contain_exactly(deleted_user_id1, deleted_user_id2)
        expect(ClickHouse::SyncCursor.cursor_for(:event_authors_consistency_check)).to eq(user2.id)
      end
    end

    context 'when time limit is reached' do
      it 'stops the processing earlier' do
        stub_const("#{ClickHouse::Concerns::ConsistencyWorker}::POSTGRESQL_BATCH_SIZE", 1)

        # stop at the third author_id
        allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |runtime_limiter|
          allow(runtime_limiter).to receive(:over_time?).and_return(false, false, true)
        end
        expect(worker).to receive(:log_extra_metadata_on_done).with(:result, { status: :over_time, modifications: 1 })

        worker.perform

        expect(leftover_author_ids).to contain_exactly(user1.id, user2.id, deleted_user_id2)
      end
    end
  end
end
