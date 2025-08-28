# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillProjectIdForProjectsWithPipelineVariables, migration: :gitlab_ci, feature_category: :pipeline_composition do
  let!(:batched_migration) { described_class::MIGRATION }

  # No-op because we decided not to pursue the migration. See https://gitlab.com/groups/gitlab-org/-/epics/16522#note_2492640881
  it 'does not schedules a new batched migration' do
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
