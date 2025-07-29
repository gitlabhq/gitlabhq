# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeEncryptMissedCiRunnerTokens, migration: :gitlab_ci, feature_category: :fleet_visibility do
  it 'finalizes the batched migration' do
    expect(described_class).to ensure_batched_background_migration_is_finished_for(
      job_class_name: 'EncryptMissedCiRunnerTokens',
      table_name: :ci_runners,
      column_name: :id,
      job_arguments: []
    )

    migrate!
  end
end
