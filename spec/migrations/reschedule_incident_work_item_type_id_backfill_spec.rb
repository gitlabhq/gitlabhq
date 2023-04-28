# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RescheduleIncidentWorkItemTypeIdBackfill, :migration, feature_category: :team_planning do
  include MigrationHelpers::WorkItemTypesHelper

  let!(:migration) { described_class::MIGRATION }
  let!(:interval) { 2.minutes }
  let!(:incident_type_enum) { 1 }
  let!(:issue_type_enum) { 0 }
  let!(:incident_work_item_type) do
    table(:work_item_types).find_by!(namespace_id: nil, base_type: incident_type_enum)
  end

  let!(:issue_work_item_type) do
    table(:work_item_types).find_by!(namespace_id: nil, base_type: issue_type_enum)
  end

  describe '#up' do
    let!(:existing_incident_migration) { create_backfill_migration(incident_type_enum, incident_work_item_type.id) }
    let!(:existing_issue_migration) { create_backfill_migration(issue_type_enum, issue_work_item_type.id) }

    it 'correctly reschedules background migration only for incidents' do
      migrate!

      migration_ids = table(:batched_background_migrations).pluck(:id)

      expect(migration).to have_scheduled_batched_migration(
        table_name: :issues,
        column_name: :id,
        job_arguments: [incident_type_enum, incident_work_item_type.id],
        interval: interval,
        batch_size: described_class::BATCH_SIZE,
        max_batch_size: described_class::MAX_BATCH_SIZE,
        sub_batch_size: described_class::SUB_BATCH_SIZE
      )
      expect(migration_ids.count).to eq(2)
      expect(migration_ids).not_to include(existing_incident_migration.id)
      expect(migration_ids).to include(existing_issue_migration.id)
    end

    it "doesn't fail if work item types don't exist on the DB" do
      table(:work_item_types).delete_all

      migrate!

      # Since migration specs run outside of a transaction, we need to make
      # sure we recreate default types since this spec deletes them all
      reset_work_item_types
    end
  end

  def create_backfill_migration(base_type, type_id)
    table(:batched_background_migrations).create!(
      job_class_name: migration,
      table_name: :issues,
      column_name: :id,
      job_arguments: [base_type, type_id],
      interval: 2.minutes,
      min_value: 1,
      max_value: 2,
      batch_size: 1000,
      sub_batch_size: 200,
      gitlab_schema: :gitlab_main,
      status: 3
    )
  end
end
