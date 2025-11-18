# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueReindexProjectElasticZoektData, migration: :gitlab_main, feature_category: :global_search do
  let!(:batched_migration) { described_class::MIGRATION }

  context 'for dotcom', :saas do
    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            table_name: :namespace_settings, column_name: :namespace_id
          )
        }
      end
    end
  end

  context 'for non dotcom' do
    it 'does not schedule a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).not_to have_scheduled_batched_migration(
            table_name: :namespace_settings, column_name: :namespace_id
          )
        }
      end
    end
  end
end
