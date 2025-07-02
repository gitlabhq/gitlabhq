# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillSentNotificationsAfterPartition, migration: :gitlab_main, feature_category: :team_planning do
  let!(:batched_migration) { described_class::MIGRATION }
  let(:sent_notifications) { table(:sent_notifications) }
  let(:partitioned_sent_notifications) { partitioned_table(:sent_notifications_7abbf02cb6) }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_main,
          table_name: :sent_notifications,
          column_name: :id,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE,
          batch_min_value: 1,
          batch_max_value: 1
        )
      }
    end
  end

  context 'when migration is run in .com', :saas do
    before do
      sent_notifications.create!(
        id: described_class::DOT_COM_START_ID - 1,
        noteable_type: 'Issue',
        noteable_id: 2,
        namespace_id: 1,
        reply_key: 'key1'
      )
      sent_notifications.create!(
        id: described_class::DOT_COM_START_ID + 1,
        noteable_type: 'Issue',
        noteable_id: 2,
        namespace_id: 1,
        reply_key: 'key2'
      )
      sent_notifications.create!(
        id: described_class::DOT_COM_START_ID + 2,
        noteable_type: 'Issue',
        noteable_id: 2,
        namespace_id: 1,
        reply_key: 'key3'
      )
    end

    it 'sets the min id to the value defined for .com' do
      migrate!

      expect(batched_migration).to have_scheduled_batched_migration(
        gitlab_schema: :gitlab_main,
        table_name: :sent_notifications,
        column_name: :id,
        batch_size: described_class::GITLAB_OPTIMIZED_BATCH_SIZE,
        sub_batch_size: described_class::GITLAB_OPTIMIZED_SUB_BATCH_SIZE,
        max_batch_size: described_class::GITLAB_OPTIMIZED_MAX_BATCH_SIZE,
        batch_min_value: described_class::DOT_COM_START_ID,
        batch_max_value: described_class::DOT_COM_START_ID + 2
      )
    end
  end

  context 'when records exist in the partitioned table already' do
    before do
      partitioned_sent_notifications.create!(
        id: 100,
        noteable_type: 'Issue',
        noteable_id: 2,
        namespace_id: 1,
        reply_key: 'key'
      )
      partitioned_sent_notifications.create!(
        id: 101,
        noteable_type: 'Issue',
        noteable_id: 2,
        namespace_id: 1,
        reply_key: 'key'
      )
    end

    it 'sets the max id to the minimum on the partitioned table' do
      migrate!

      expect(batched_migration).to have_scheduled_batched_migration(
        gitlab_schema: :gitlab_main,
        table_name: :sent_notifications,
        column_name: :id,
        batch_size: described_class::BATCH_SIZE,
        sub_batch_size: described_class::SUB_BATCH_SIZE,
        batch_min_value: 1,
        batch_max_value: 100
      )
    end
  end
end
