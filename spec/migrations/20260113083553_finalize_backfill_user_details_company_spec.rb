# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillUserDetailsCompany, migration: :gitlab_main_org, feature_category: :organization do
  let(:migration_name) { 'BackfillUserDetailsCompany' }
  let(:table_name) { :user_details }
  let(:column_name) { :user_id }
  let(:batched_background_migration) { table(:batched_background_migrations) }
  let!(:migration) do
    batched_background_migration.create!(
      job_class_name: migration_name,
      table_name: table_name,
      column_name: column_name,
      job_arguments: [],
      batch_size: 100_000,
      sub_batch_size: 1_000,
      interval: 10,
      gitlab_schema: :gitlab_main_org,
      min_value: 1,
      max_value: 2,
      status: 3 # Finished
    )
  end

  it 'finalizes the batched background migration' do
    reversible_migration do |migration_runner|
      migration_runner.after -> {
        expect(migration.reload.status).to eq(6) # Finalized
      }
    end
  end
end
