# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe PopulateOperationVisibilityPermissions, :migration, feature_category: :navigation do
  let(:migration) { described_class::MIGRATION }

  before do
    stub_const("#{described_class.name}::SUB_BATCH_SIZE", 2)
  end

  it 'schedules background migrations', :aggregate_failures do
    migrate!

    expect(migration).to have_scheduled_batched_migration(
      table_name: :project_features,
      column_name: :id,
      interval: described_class::INTERVAL
    )
  end

  describe '#down' do
    it 'deletes all batched migration records' do
      migrate!
      schema_migrate_down!

      expect(migration).not_to have_scheduled_batched_migration
    end
  end
end
