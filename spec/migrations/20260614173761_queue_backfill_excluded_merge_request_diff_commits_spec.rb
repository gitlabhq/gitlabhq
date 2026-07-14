# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillExcludedMergeRequestDiffCommits, migration: :gitlab_main,
  feature_category: :code_review_workflow do
  let!(:batched_migration) { described_class::MIGRATION }

  describe '#up' do
    it 'is a no-op' do
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
end
