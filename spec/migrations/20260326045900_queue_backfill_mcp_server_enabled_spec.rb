# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillMcpServerEnabled, migration: :gitlab_main, feature_category: :mcp_server do
  it 'schedules a batched background migration' do
    migrate!
    expect(described_class::MIGRATION).to have_scheduled_batched_migration(
      table_name: :namespaces,
      column_name: :id,
      batch_size: described_class::BATCH_SIZE,
      sub_batch_size: described_class::SUB_BATCH_SIZE
    )
  end

  describe '#down' do
    it 'removes scheduled migration' do
      migrate!
      schema_migrate_down!
      expect(described_class::MIGRATION).not_to have_scheduled_batched_migration
    end
  end
end
