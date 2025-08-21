# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillDesignManagementRepositoryStatesNamespaceId, feature_category: :geo_replication do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :design_management_repository_states,
          column_name: :design_management_repository_id,
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE,
          gitlab_schema: :gitlab_main_org,
          job_arguments: [
            :namespace_id,
            :design_management_repositories,
            :namespace_id,
            :design_management_repository_id
          ]
        )
      }
    end
  end
end
