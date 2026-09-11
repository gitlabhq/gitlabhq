# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMissingEpicIssuesFromParentLinks, feature_category: :portfolio_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:issues) { table(:issues) }
  let(:epics) { table(:epics) }
  let(:parent_links) { table(:work_item_parent_links) }
  let(:epic_issues) { table(:epic_issues) }

  let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let!(:group) { namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id) }
  let!(:project_namespace) do
    namespaces.create!(name: 'project', path: 'project', type: 'Project', parent_id: group.id,
      organization_id: organization.id)
  end

  let!(:project) do
    projects.create!(name: 'project', path: 'project', namespace_id: group.id,
      project_namespace_id: project_namespace.id, organization_id: organization.id)
  end

  let!(:author) do
    users.create!(username: 'author', email: 'author@example.com', projects_limit: 10,
      organization_id: organization.id)
  end

  let!(:epic_work_item) { create_work_item(epic_work_item_type_id) }
  let!(:epic) { create_epic(iid: 1, work_item: epic_work_item) }

  # project issue under the epic with a parent link but no epic_issues row
  let!(:orphaned_issue) { create_work_item(issue_work_item_type_id, namespace: project_namespace, project: project) }
  let!(:orphaned_link) { create_link(orphaned_issue, epic_work_item, relative_position: 20) }

  # issue under the epic with a parent link but no epic_issues row and no position
  let!(:unpositioned_issue) { create_work_item(issue_work_item_type_id) }

  # second epic with its own affected issue, to prove rows are not cross-wired between epics
  let!(:other_epic) { create_epic(iid: 3, work_item: create_work_item(epic_work_item_type_id)) }
  let!(:other_orphaned_issue) { create_work_item(issue_work_item_type_id) }
  let!(:other_orphaned_link) do
    create_link(other_orphaned_issue, issues.find(other_epic.issue_id), relative_position: 40)
  end

  # issue under the epic that is correctly synced
  let!(:synced_issue) { create_work_item(issue_work_item_type_id) }
  let!(:synced_epic_issue) do
    link = create_link(synced_issue, epic_work_item, relative_position: 10)

    epic_issues.create!(
      epic_id: epic.id, issue_id: synced_issue.id, namespace_id: group.id,
      work_item_parent_link_id: link.id, relative_position: 10
    )
  end

  # issue linked to the epic whose existing epic_issues row still points at another epic
  let!(:mismatched_issue) { create_work_item(issue_work_item_type_id) }
  let!(:mismatched_epic_issue) do
    link = create_link(mismatched_issue, epic_work_item, relative_position: 50)

    epic_issues.create!(
      epic_id: other_epic.id, issue_id: mismatched_issue.id, namespace_id: group.id, work_item_parent_link_id: link.id
    )
  end

  subject(:migration) do
    described_class.new(
      start_cursor: [epics.minimum(:id)],
      end_cursor: [epics.maximum(:id)],
      batch_table: :epics,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  before do
    create_link(unpositioned_issue, epic_work_item)

    # epic under the epic, synced through epics.parent_id instead of epic_issues
    child_epic_work_item = create_work_item(epic_work_item_type_id)
    create_epic(iid: 2, work_item: child_epic_work_item)
    create_link(child_epic_work_item, epic_work_item, relative_position: 30)

    # task under an issue, no epic involved
    task_parent = create_work_item(issue_work_item_type_id)
    create_link(create_work_item(issue_work_item_type_id), task_parent)
  end

  describe '#perform' do
    it 'creates the missing epic_issues rows from the parent links', :aggregate_failures do
      expect { migration.perform }.to change { epic_issues.count }.by(3)

      created = epic_issues.find_by!(issue_id: orphaned_issue.id)

      expect(created.epic_id).to eq(epic.id)
      expect(created.work_item_parent_link_id).to eq(orphaned_link.id)
      expect(created.relative_position).to eq(orphaned_link.relative_position)
      expect(created.namespace_id).to eq(project_namespace.id)

      expect(epic_issues.find_by!(issue_id: unpositioned_issue.id).relative_position).to be_nil
    end

    it 'does not touch links that already have an epic_issues row', :aggregate_failures do
      migration.perform

      expect(synced_epic_issue.reload.epic_id).to eq(epic.id)
      expect(epic_issues.where(issue_id: synced_issue.id).count).to eq(1)
    end

    it 'leaves rows that point at a different epic than the parent link untouched', :aggregate_failures do
      migration.perform

      expect(mismatched_epic_issue.reload.epic_id).to eq(other_epic.id)
      expect(epic_issues.where(issue_id: mismatched_issue.id).count).to eq(1)
    end

    it 'writes rows only for issue children of epics' do
      migration.perform

      expect(epic_issues.pluck(:issue_id)).to match_array(
        [orphaned_issue.id, unpositioned_issue.id, other_orphaned_issue.id, synced_issue.id, mismatched_issue.id]
      )
    end

    it 'links each row to its own epic and parent link', :aggregate_failures do
      migration.perform

      expect(epic_issues.where(issue_id: orphaned_issue.id).pick(:epic_id, :work_item_parent_link_id))
        .to eq([epic.id, orphaned_link.id])
      expect(epic_issues.where(issue_id: other_orphaned_issue.id).pick(:epic_id, :work_item_parent_link_id))
        .to eq([other_epic.id, other_orphaned_link.id])
    end

    it 'is idempotent' do
      migration.perform

      expect { migration.perform }.not_to change { epic_issues.count }
    end
  end

  def issue_work_item_type_id
    1
  end

  def epic_work_item_type_id
    8
  end

  def create_work_item(work_item_type_id, namespace: group, project: nil)
    iid = (issues.where(namespace_id: namespace.id).maximum(:iid) || 0) + 1

    issues.create!(
      title: "Work item #{iid}", iid: iid, namespace_id: namespace.id, project_id: project&.id,
      work_item_type_id: work_item_type_id, author_id: author.id
    )
  end

  def create_epic(iid:, work_item:)
    epics.create!(
      iid: iid, group_id: group.id, author_id: author.id, issue_id: work_item.id,
      title: "Epic #{iid}", title_html: "Epic #{iid}"
    )
  end

  def create_link(work_item, parent_work_item, relative_position: nil)
    parent_links.create!(
      work_item_id: work_item.id, work_item_parent_id: parent_work_item.id,
      namespace_id: work_item.namespace_id, relative_position: relative_position
    )
  end
end
