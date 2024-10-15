# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillPackagesNpmMetadataProjectId, feature_category: :package_registry do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :packages_npm_metadata,
          column_name: :package_id,
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE,
          gitlab_schema: :gitlab_main_cell,
          job_arguments: [
            :project_id,
            :packages_packages,
            :project_id,
            :package_id
          ]
        )
      }
    end
  end
end
