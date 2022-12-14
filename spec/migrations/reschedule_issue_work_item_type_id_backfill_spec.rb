# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RescheduleIssueWorkItemTypeIdBackfill, :migration, feature_category: :team_planning do
  let!(:migration) { described_class::MIGRATION }
  let!(:interval) { 2.minutes }
  let!(:issue_type_enum) { { issue: 0, incident: 1, test_case: 2, requirement: 3, task: 4 } }
  let!(:base_work_item_type_ids) do
    table(:work_item_types).where(namespace_id: nil).order(:base_type).each_with_object({}) do |type, hash|
      hash[type.base_type] = type.id
    end
  end

  describe '#up' do
    it 'correctly schedules background migrations' do
      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          scheduled_migrations = Gitlab::Database::BackgroundMigration::BatchedMigration.where(
            job_class_name: migration
          )
          work_item_types = table(:work_item_types).where(namespace_id: nil)

          expect(scheduled_migrations.count).to eq(work_item_types.count)

          [:issue, :incident, :test_case, :requirement, :task].each do |issue_type|
            expect(migration).to have_scheduled_batched_migration(
              table_name: :issues,
              column_name: :id,
              job_arguments: [issue_type_enum[issue_type], base_work_item_type_ids[issue_type_enum[issue_type]]],
              interval: interval,
              batch_size: described_class::BATCH_SIZE,
              max_batch_size: described_class::MAX_BATCH_SIZE,
              sub_batch_size: described_class::SUB_BATCH_SIZE,
              batch_class_name: described_class::BATCH_CLASS_NAME
            )
          end
        end
      end
    end
  end

  describe '#down' do
    it 'deletes all batched migration records' do
      migrate!
      schema_migrate_down!

      expect(migration).not_to have_scheduled_batched_migration
    end
  end
end
