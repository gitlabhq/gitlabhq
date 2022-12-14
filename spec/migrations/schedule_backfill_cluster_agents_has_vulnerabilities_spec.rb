# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleBackfillClusterAgentsHasVulnerabilities, feature_category: :vulnerability_management do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules background jobs for each batch of cluster agents' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :cluster_agents,
          column_name: :id,
          interval: described_class::DELAY_INTERVAL
        )
      }
    end
  end
end
