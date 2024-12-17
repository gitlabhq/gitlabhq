# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillEventsShardingKey, :migration_with_transaction, feature_category: :database do
  let(:connection) { ApplicationRecord.connection }

  describe '#perform' do
    let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
    let!(:namespace) { table(:namespaces).create!(name: 'name', path: 'path', organization_id: organization.id) }
    let!(:project) do
      table(:projects).create!(
        namespace_id: namespace.id,
        project_namespace_id: namespace.id,
        organization_id: organization.id
      )
    end

    let!(:user) { table(:users).create!(username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 1) }
    let!(:note) { table(:notes).create!(noteable_type: 'Issue', project_id: project.id) }
    let!(:mr) do
      table(:merge_requests).create!(target_project_id: project.id, target_branch: 'main', source_branch: 'not-main')
    end

    let!(:design) do
      table(:design_management_designs).create!(project_id: project.id, filename: 'final_v2.jpg', iid: 42)
    end

    let!(:milestone) { table(:milestones).create!(title: 'Backlog', project_id: project.id) }
    let!(:wpm_project) { table(:wiki_page_meta).create!(title: 'Backlog', project_id: project.id) }
    let!(:wpm_group) { table(:wiki_page_meta).create!(title: 'Backlog', namespace_id: namespace.id) }
    let(:issue_type) { table(:work_item_types).find_by(name: 'Issue') }
    let!(:issue) do
      table(:issues).create!(project_id: project.id, namespace_id: namespace.id, work_item_type_id: issue_type.id)
    end

    let!(:epic) do
      table(:epics).create!(title: "epic", title_html: "epic", iid: 1, author_id: user.id, group_id: namespace.id,
        issue_id: issue.id)
    end

    let!(:personal_namespace) do
      table(:namespaces).create!(name: 'personal', path: 'personal', owner_id: user.id, type: 'User',
        organization_id: organization.id)
    end

    let!(:deleted_user) { table(:users).create!(username: 'deleted', email: 'deleted@gitlab.com', projects_limit: 1) }

    let(:events) { table(:events) }

    it 'populates sharding key and removes records without sharding key' do
      # Remove constraint so we can create invalid records
      connection.execute('ALTER TABLE events DROP CONSTRAINT check_events_sharding_key_is_not_null')

      with_project = events.create!(project_id: project.id, author_id: user.id, action: 1)
      with_group = events.create!(group_id: namespace.id, author_id: user.id, action: 1)
      for_note_without_project = events.create!(author_id: user.id, action: 1, target_type: 'Note', target_id: note.id)
      for_mr_without_project = events.create!(author_id: user.id, action: 1, target_type: 'MergeRequest',
        target_id: mr.id)
      for_design_without_project = events.create!(author_id: user.id, action: 1,
        target_type: 'DesignManagement::Design', target_id: design.id)
      for_issue_without_project = events.create!(author_id: user.id, action: 1, target_type: 'Issue',
        target_id: issue.id)
      for_milestone_without_project = events.create!(author_id: user.id, action: 1, target_type: 'Milestone',
        target_id: milestone.id)
      for_wiki_page_meta_without_project = events.create!(author_id: user.id, action: 1, target_type: 'WikiPage::Meta',
        target_id: wpm_project.id)
      for_wiki_page_meta_without_group = events.create!(author_id: user.id, action: 1, target_type: 'WikiPage::Meta',
        target_id: wpm_group.id)
      for_epic_without_group = events.create!(author_id: user.id, action: 1, target_type: 'Epic', target_id: epic.id)
      needs_personal_namespace = events.create!(author_id: user.id, action: 1)
      to_be_deleted = events.create!(author_id: deleted_user.id, action: 1)

      # Re-create constraint so that invalid updates fail
      connection.execute(
        <<~SQL
          ALTER TABLE events ADD CONSTRAINT check_events_sharding_key_is_not_null
          CHECK (((group_id IS NOT NULL) OR (project_id IS NOT NULL) OR (personal_namespace_id IS NOT NULL))) NOT VALID
        SQL
      )

      migration = described_class.new(
        start_id: with_project.id,
        end_id: to_be_deleted.id,
        batch_table: :events,
        batch_column: :id,
        sub_batch_size: 10,
        pause_ms: 0,
        connection: connection
      )

      expect { migration.perform }.to change { for_note_without_project.reload.project_id }.from(nil).to(project.id)
        .and change { for_mr_without_project.reload.project_id }.from(nil).to(project.id)
        .and change { for_design_without_project.reload.project_id }.from(nil).to(project.id)
        .and change { for_issue_without_project.reload.project_id }.from(nil).to(project.id)
        .and change { for_milestone_without_project.reload.project_id }.from(nil).to(project.id)
        .and change { for_wiki_page_meta_without_project.reload.project_id }.from(nil).to(project.id)
        .and change { for_wiki_page_meta_without_group.reload.group_id }.from(nil).to(namespace.id)
        .and change { for_epic_without_group.reload.group_id }.from(nil).to(namespace.id)
        .and change { needs_personal_namespace.reload.personal_namespace_id }.from(nil).to(personal_namespace.id)

      expect(events.find_by_id(with_project.id)).to be_present
      expect(events.find_by_id(with_group.id)).to be_present
      expect(events.find_by_id(for_note_without_project.id)).to be_present
      expect(events.find_by_id(for_mr_without_project.id)).to be_present
      expect(events.find_by_id(for_design_without_project.id)).to be_present
      expect(events.find_by_id(for_issue_without_project.id)).to be_present
      expect(events.find_by_id(for_milestone_without_project.id)).to be_present
      expect(events.find_by_id(for_wiki_page_meta_without_project.id)).to be_present
      expect(events.find_by_id(for_wiki_page_meta_without_group.id)).to be_present
      expect(events.find_by_id(for_epic_without_group.id)).to be_present
      expect(events.find_by_id(to_be_deleted.id)).not_to be_present
    end
  end
end
