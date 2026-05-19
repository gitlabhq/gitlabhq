# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDescriptionVersionsForEpics, feature_category: :portfolio_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:issues) { table(:issues) }
  let(:epics) { table(:epics) }
  let(:description_versions) { table(:description_versions) }

  let!(:organization) { organizations.create!(name: 'test-org', path: 'test-org') }
  let!(:group_namespace) do
    namespaces.create!(name: 'test-group', path: 'test-group', type: 'Group', organization_id: organization.id)
  end

  let!(:author) do
    users.create!(username: 'author', email: 'author@example.com', projects_limit: 0,
      organization_id: organization.id)
  end

  # Work item type IDs are fixed now and only exist in memory.
  let(:issue_type_id) { 1 }
  let(:epic_type_id) { 8 }

  let!(:epic_work_item) do
    issues.create!(
      title: 'Epic Work Item',
      iid: 1,
      namespace_id: group_namespace.id,
      work_item_type_id: epic_type_id
    )
  end

  let!(:other_issue) do
    issues.create!(
      title: 'Other Issue',
      iid: 2,
      namespace_id: group_namespace.id,
      work_item_type_id: issue_type_id
    )
  end

  let!(:epic) do
    epics.create!(
      iid: 1,
      group_id: group_namespace.id,
      author_id: author.id,
      title: 'Epic',
      title_html: 'Epic',
      issue_id: epic_work_item.id
    )
  end

  # Linked to an epic - should have issue_id set and epic_id cleared
  let!(:dv_linked_to_epic) do
    description_versions.create!(
      epic_id: epic.id,
      namespace_id: group_namespace.id,
      description: 'description version 1'
    )
  end

  # Already linked to an issue directly - should not be changed
  let!(:dv_linked_to_issue) do
    description_versions.create!(
      issue_id: other_issue.id,
      namespace_id: group_namespace.id,
      description: 'description version 2'
    )
  end

  subject(:perform_migration) do
    described_class.new(
      start_cursor: [epics.minimum(:id)],
      end_cursor: [epics.maximum(:id)],
      batch_table: :epics,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    ).perform
  end

  describe '#perform' do
    it 'sets issue_id from the linked epic and clears epic_id' do
      expect { perform_migration }
        .to change { dv_linked_to_epic.reload.issue_id }.from(nil).to(epic_work_item.id)
        .and change { dv_linked_to_epic.reload.epic_id }.from(epic.id).to(nil)
    end

    it 'does not update description_versions that are not linked to an epic' do
      expect { perform_migration }
        .to not_change { dv_linked_to_issue.reload.issue_id }.from(other_issue.id)
        .and not_change { dv_linked_to_issue.reload.epic_id }.from(nil)
    end
  end
end
