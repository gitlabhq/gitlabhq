# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillResourceLinkEvents, feature_category: :team_planning do
  include MigrationHelpers::WorkItemTypesHelper

  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:issues) { table(:issues) }
  let(:notes) { table(:notes) }
  let(:system_note_metadata) { table(:system_note_metadata) }

  let(:namespace) { namespaces.create!(name: "namespace", path: "namespace") }
  let(:project) { projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }
  let(:work_item_issue_type_id) { table(:work_item_types).find_by(namespace_id: nil, name: 'Issue').id }
  let(:issue) { issues.create!(project_id: project.id, namespace_id: project.project_namespace_id, work_item_type_id: work_item_issue_type_id) } # rubocop:disable Layout/LineLength
  let(:user) { users.create!(name: 'user', projects_limit: 10) }

  let!(:system_note_metadata_record1) do
    note = notes.create!(noteable_type: 'Issue', noteable_id: issue.id, author_id: user.id, note: "foobar")

    system_note_metadata.create!(action: 'foobar', note_id: note.id)
  end

  let!(:batched_migration) { described_class::MIGRATION }

  describe '#up' do
    %w[relate_to_parent unrelate_from_parent].each do |action_value|
      context 'when system_note_metadata table has a row with targeted action values' do
        let!(:system_note_metadata_record2) do
          note = notes.create!(noteable_type: 'Issue', noteable_id: issue.id, author_id: user.id, note: "foobar")

          system_note_metadata.create!(action: action_value, note_id: note.id)
        end

        let!(:system_note_metadata_record3) do
          note = notes.create!(noteable_type: 'Issue', noteable_id: issue.id, author_id: user.id, note: "foobar")

          system_note_metadata.create!(action: action_value, note_id: note.id)
        end

        it 'schedules a new batched migration with the lowest system_note_metadat record id' do
          reversible_migration do |migration|
            migration.before -> {
              expect(batched_migration).not_to have_scheduled_batched_migration
            }

            migration.after -> {
              expect(batched_migration).to have_scheduled_batched_migration(
                table_name: :system_note_metadata,
                column_name: :id,
                interval: described_class::DELAY_INTERVAL,
                batch_size: described_class::BATCH_SIZE,
                sub_batch_size: described_class::SUB_BATCH_SIZE,
                batch_min_value: system_note_metadata_record2.id
              )
            }
          end
        end
      end
    end

    context 'when system_note_metadata table does not ahve a row with the targeted action values' do
      it 'does not a new batched migration' do
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

  describe '#down' do
    it 'deletes all batched migration records' do
      migrate!
      schema_migrate_down!

      expect(batched_migration).not_to have_scheduled_batched_migration
    end
  end
end
