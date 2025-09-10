# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueCleanupTerminatedBulkImportConfigs, migration: :gitlab_main, feature_category: :importers do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    expect(batched_migration).not_to have_scheduled_batched_migration

    migrate!

    expect(batched_migration).to have_scheduled_batched_migration(
      gitlab_schema: :gitlab_main_org,
      table_name: :bulk_imports,
      column_name: :id,
      batch_size: described_class::BATCH_SIZE,
      sub_batch_size: described_class::SUB_BATCH_SIZE
    )
  end
end
