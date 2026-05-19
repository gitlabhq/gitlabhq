# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueRenameDeprecatedAssignablePermissions,
  migration: :gitlab_main_org,
  feature_category: :permissions do
  let(:migration) { described_class::MIGRATION }

  it 'schedules a batched migration' do
    reversible_migration do |m|
      m.before -> {
        expect(migration).not_to have_scheduled_batched_migration
      }

      m.after -> {
        expect(migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_main_org,
          table_name: :granular_scopes,
          column_name: :id,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )
      }
    end
  end
end
