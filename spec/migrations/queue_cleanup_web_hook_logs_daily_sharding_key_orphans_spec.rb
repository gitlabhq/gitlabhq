# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueCleanupWebHookLogsDailyShardingKeyOrphans, feature_category: :webhooks do
  let(:batched_migration) { described_class::MIGRATION }

  let(:organizations) { table(:organizations) }
  let(:web_hooks) { table(:web_hooks) }
  let(:web_hook_logs_daily) { table(:web_hook_logs_daily) }

  let(:organization) { organizations.create!(name: 'Default', path: 'default') }
  let(:hook) { web_hooks.create!(type: 'SystemHook', organization_id: organization.id) }

  # web_hook_logs_daily keeps a 7-day sliding window of daily partitions, so
  # timestamps must be relative to the current date to fall within a partition.
  let!(:first_log) { create_log(created_at: 1.day.ago.change(usec: 0)) }
  let!(:last_log) { create_log(created_at: Time.current.change(usec: 0)) }

  context 'when not on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    it 'schedules a new batched migration with cursor bounds over the composite primary key' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            table_name: :web_hook_logs_daily,
            column_name: :id,
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE,
            min_cursor: [first_log[:id], first_log.created_at.as_json],
            max_cursor: [last_log[:id], last_log.created_at.as_json]
          )
        }
      end
    end
  end

  context 'when on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    it 'does not schedule a batched migration' do
      migrate!

      expect(batched_migration).not_to have_scheduled_batched_migration
    end
  end

  private

  # The sharding-key trigger assigns organization_id from the parent hook, satisfying the
  # NOT VALID check constraint (which is still enforced for new inserts).
  def create_log(created_at:)
    web_hook_logs_daily.create!(
      web_hook_id: hook.id,
      trigger: 'push_hooks',
      url: 'http://example.com',
      request_headers: {},
      request_data: {},
      response_headers: {},
      response_body: '',
      response_status: '200',
      execution_duration: 0.1,
      internal_error_message: '',
      created_at: created_at,
      updated_at: created_at
    )
  end
end
