# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeMigrateEpicLabelLinksToWorkItems, migration: :gitlab_main_org, feature_category: :portfolio_management do
  it 'finalizes the batched background migration' do
    expect(described_class).to ensure_batched_background_migration_is_finished_for(
      job_class_name: 'MigrateEpicLabelLinksToWorkItems',
      table_name: :epics,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )

    migrate!
  end
end
