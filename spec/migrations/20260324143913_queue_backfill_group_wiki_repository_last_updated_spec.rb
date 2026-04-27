# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillGroupWikiRepositoryLastUpdated, migration: :gitlab_main, feature_category: :geo_replication do
  let!(:batched_migration) { described_class::MIGRATION }

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
