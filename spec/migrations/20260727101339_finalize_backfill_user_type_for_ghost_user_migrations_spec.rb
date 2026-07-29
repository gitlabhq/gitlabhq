# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillUserTypeForGhostUserMigrations, migration: :gitlab_main_user, feature_category: :user_profile do
  it 'finalizes the batched background migration' do
    expect(described_class).to ensure_batched_background_migration_is_finished_for(
      job_class_name: 'BackfillUserTypeForGhostUserMigrations',
      table_name: :ghost_user_migrations,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )

    migrate!
  end
end
