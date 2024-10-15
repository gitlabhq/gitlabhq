# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ReenqueueDeduplicateLfsObjectsProjectsWithNullRepositoryTypes, feature_category: :source_code_management do
  let(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :lfs_objects_projects,
          column_name: :id,
          batch_class_name: described_class::BATCH_CLASS_NAME,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )
      }
    end
  end
end
