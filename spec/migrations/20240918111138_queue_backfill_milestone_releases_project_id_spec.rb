# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillMilestoneReleasesProjectId, feature_category: :release_orchestration do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'does not schedule a new batched migration' do
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
