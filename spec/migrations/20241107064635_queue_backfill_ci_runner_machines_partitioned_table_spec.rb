# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillCiRunnerMachinesPartitionedTable, migration: :gitlab_ci,
  feature_category: :fleet_visibility do
  let!(:batched_migration) { 'BackfillCiRunnerMachinesPartitionedTable' }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }
    end
  end
end
