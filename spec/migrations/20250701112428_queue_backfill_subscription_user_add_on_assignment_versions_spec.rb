# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillSubscriptionUserAddOnAssignmentVersions, migration: :gitlab_main, feature_category: :value_stream_management do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'does nothing' do
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
