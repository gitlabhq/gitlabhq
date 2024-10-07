# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueRecoverDeletedMlModelVersionPackages, feature_category: :mlops do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :ml_model_versions,
          column_name: :id,
          interval: 2.minutes,
          batch_size: 1000,
          sub_batch_size: 100
        )
      }
    end
  end
end
