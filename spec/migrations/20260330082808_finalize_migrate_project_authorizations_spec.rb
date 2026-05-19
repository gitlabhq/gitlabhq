# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeMigrateProjectAuthorizations, migration: :gitlab_main, feature_category: :user_management do
  it 'finalizes the batched background migration' do
    expect(described_class).to ensure_batched_background_migration_is_finished_for(
      job_class_name: 'MigrateProjectAuthorizations',
      table_name: :project_authorizations,
      column_name: :user_id,
      job_arguments: [],
      finalize: true
    )

    migrate!
  end
end
