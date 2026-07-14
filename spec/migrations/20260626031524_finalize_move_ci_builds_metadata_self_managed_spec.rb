# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeMoveCiBuildsMetadataSelfManaged, migration: :gitlab_ci,
  feature_category: :continuous_integration do
  let(:batched_background_migration) { table(:batched_background_migrations) }

  let!(:migration) do
    batched_background_migration.create!(
      job_class_name: 'MoveCiBuildsMetadataSelfManaged',
      table_name: 'gitlab_partitions_dynamic.ci_builds_100',
      column_name: :id,
      job_arguments: ['partition_id', [100]],
      batch_size: 1_000,
      sub_batch_size: 100,
      interval: 120,
      gitlab_schema: :gitlab_ci,
      min_value: 1,
      max_value: 2,
      status: 3 # Finished
    )
  end

  it 'finalizes the batched background migration', :aggregate_failures do
    reversible_migration do |migration_runner|
      migration_runner.after -> {
        expect(migration.reload.status).to eq(6) # Finalized
      }
    end
  end
end
