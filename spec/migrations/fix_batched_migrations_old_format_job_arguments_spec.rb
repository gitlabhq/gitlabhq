# frozen_string_literal: true

require 'spec_helper'
require_migration!

# rubocop:disable Style/WordArray
RSpec.describe FixBatchedMigrationsOldFormatJobArguments do
  let(:batched_background_migrations) { table(:batched_background_migrations) }

  context 'when migrations with legacy job arguments exists' do
    it 'updates job arguments to current format' do
      legacy_events_migration = create_batched_migration('events', 'id', ['id', 'id_convert_to_bigint'])
      legacy_push_event_payloads_migration = create_batched_migration('push_event_payloads', 'event_id', ['event_id', 'event_id_convert_to_bigint'])

      migrate!

      expect(legacy_events_migration.reload.job_arguments).to eq([['id'], ['id_convert_to_bigint']])
      expect(legacy_push_event_payloads_migration.reload.job_arguments).to eq([['event_id'], ['event_id_convert_to_bigint']])
    end
  end

  context 'when only migrations with current job arguments exists' do
    it 'updates nothing' do
      events_migration = create_batched_migration('events', 'id', [['id'], ['id_convert_to_bigint']])
      push_event_payloads_migration = create_batched_migration('push_event_payloads', 'event_id', [['event_id'], ['event_id_convert_to_bigint']])

      migrate!

      expect(events_migration.reload.job_arguments).to eq([['id'], ['id_convert_to_bigint']])
      expect(push_event_payloads_migration.reload.job_arguments).to eq([['event_id'], ['event_id_convert_to_bigint']])
    end
  end

  context 'when migrations with both legacy and current job arguments exist' do
    it 'updates nothing' do
      legacy_events_migration = create_batched_migration('events', 'id', ['id', 'id_convert_to_bigint'])
      events_migration = create_batched_migration('events', 'id', [['id'], ['id_convert_to_bigint']])
      legacy_push_event_payloads_migration = create_batched_migration('push_event_payloads', 'event_id', ['event_id', 'event_id_convert_to_bigint'])
      push_event_payloads_migration = create_batched_migration('push_event_payloads', 'event_id', [['event_id'], ['event_id_convert_to_bigint']])

      migrate!

      expect(legacy_events_migration.reload.job_arguments).to eq(['id', 'id_convert_to_bigint'])
      expect(events_migration.reload.job_arguments).to eq([['id'], ['id_convert_to_bigint']])
      expect(legacy_push_event_payloads_migration.reload.job_arguments).to eq(['event_id', 'event_id_convert_to_bigint'])
      expect(push_event_payloads_migration.reload.job_arguments).to eq([['event_id'], ['event_id_convert_to_bigint']])
    end
  end

  def create_batched_migration(table_name, column_name, job_arguments)
    batched_background_migrations.create!(
      max_value: 10,
      batch_size: 10,
      sub_batch_size: 10,
      interval: 1,
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: table_name,
      column_name: column_name,
      job_arguments: job_arguments
    )
  end
end
# rubocop:enable Style/WordArray
