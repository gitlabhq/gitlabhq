# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RequeueBackfillGroupWikiRepositoryLastUpdated, migration: :gitlab_main, feature_category: :geo_replication do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_main,
          table_name: :group_wiki_repositories,
          column_name: :group_id,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )
      }
    end
  end
end
