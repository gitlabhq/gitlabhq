# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RequeueBackfillGroupIdAndUserTypeForHumanUsersPersonalAccessTokens, migration: :gitlab_main, feature_category: :system_access do # rubocop:disable RSpec/SpecFilePathFormat -- 20250918155823_requeue_backfill_group_id_and_user_type_for_human_users_personal_access_tokens_spec.rb is too long
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_main,
          table_name: :personal_access_tokens,
          column_name: :id,
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )
      }
    end
  end
end
