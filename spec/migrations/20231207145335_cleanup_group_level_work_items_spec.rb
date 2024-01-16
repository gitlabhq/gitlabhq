# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupGroupLevelWorkItems, feature_category: :team_planning do
  include MigrationHelpers::WorkItemTypesHelper

  let(:users) { table(:users) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:issues) { table(:issues) }
  let(:notes) { table(:notes) }
  let(:labels) { table(:labels) }
  let(:label_links) { table(:label_links) }
  let(:todos) { table(:todos) }
  let(:work_item_types) { table(:work_item_types) }

  let!(:user) { users.create!(name: 'Test User', email: 'test@example.com', projects_limit: 5) }

  let!(:group1) { namespaces.create!(name: 'group1', path: 'group1', type: 'Group') }
  let!(:group2) { namespaces.create!(name: 'group2', path: 'group2', type: 'Group') }
  let!(:project_namespace) { namespaces.create!(name: 'project1', path: 'project1', type: 'Project') }
  let!(:project) do
    projects.create!(
      name: 'project1', path: 'project1', namespace_id: group1.id, project_namespace_id: project_namespace.id
    )
  end

  let!(:issue_type) do
    ensure_work_item_type_exists
    work_item_types.first
  end

  let!(:group1_issue1) { issues.create!(title: 'Issue1-1', namespace_id: group1.id, work_item_type_id: issue_type.id) }
  let!(:group1_issue2) { issues.create!(title: 'Issue1-2', namespace_id: group1.id, work_item_type_id: issue_type.id) }
  let!(:group2_issue1) { issues.create!(title: 'Issue2-1', namespace_id: group2.id, work_item_type_id: issue_type.id) }
  let!(:group2_issue2) { issues.create!(title: 'Issue2-2', namespace_id: group2.id, work_item_type_id: issue_type.id) }
  let!(:project_issue) do
    issues.create!(
      title: 'Issue2', project_id: project.id, namespace_id: project_namespace.id, work_item_type_id: issue_type.id
    )
  end

  # associated labels
  let!(:label1) { labels.create!(title: 'label1', group_id: group1.id) }
  let!(:label2) { labels.create!(title: 'label2', group_id: group2.id) }

  after(:all) do
    # Make sure base types are recreated after running the migration
    # because migration specs are not run in a transaction
    reset_work_item_types
  end

  describe '#up' do
    before do
      # stub batch to make sure we are also testing the batching deletion
      stub_const("#{described_class}::BATCH_SIZE", 2)

      # Project label_link that must not be deleted
      label_links.create!(label_id: label1.id, target_id: project_issue.id, target_type: 'Issue')

      label_links.create!(label_id: label1.id, target_id: group1_issue1.id, target_type: 'Issue')
      label_links.create!(label_id: label2.id, target_id: group1_issue1.id, target_type: 'Issue')
      label_links.create!(label_id: label1.id, target_id: group1_issue2.id, target_type: 'Issue')
      label_links.create!(label_id: label2.id, target_id: group1_issue2.id, target_type: 'Issue')
      label_links.create!(label_id: label1.id, target_id: group2_issue1.id, target_type: 'Issue')
      label_links.create!(label_id: label2.id, target_id: group2_issue1.id, target_type: 'Issue')
      label_links.create!(label_id: label1.id, target_id: group2_issue2.id, target_type: 'Issue')
      label_links.create!(label_id: label2.id, target_id: group2_issue2.id, target_type: 'Issue')

      # associated notes

      # Project issue note that must not be deleted
      notes.create!(
        noteable_id: project_issue.id,
        noteable_type: 'Issue',
        project_id: project.id,
        namespace_id: project_namespace.id,
        note: "project issue 1 note 1"
      )

      notes.create!(
        noteable_id: group1_issue1.id, noteable_type: 'Issue', namespace_id: group1.id, note: "group1 issue 1 note 1"
      )
      notes.create!(
        noteable_id: group1_issue1.id, noteable_type: 'Issue', namespace_id: group1.id, note: "group1 issue 1 note 2"
      )
      notes.create!(
        noteable_id: group1_issue2.id, noteable_type: 'Issue', namespace_id: group1.id, note: "group1 issue 2 note 1"
      )
      notes.create!(
        noteable_id: group1_issue2.id, noteable_type: 'Issue', namespace_id: group1.id, note: "group1 issue 2 note 2"
      )
      notes.create!(
        noteable_id: group2_issue1.id, noteable_type: 'Issue', namespace_id: group2.id, note: "group2 issue 1 note 1"
      )
      notes.create!(
        noteable_id: group2_issue1.id, noteable_type: 'Issue', namespace_id: group2.id, note: "group2 issue 1 note 2"
      )
      notes.create!(
        noteable_id: group2_issue2.id, noteable_type: 'Issue', namespace_id: group2.id, note: "group2 issue 2 note 1"
      )
      notes.create!(
        noteable_id: group2_issue2.id, noteable_type: 'Issue', namespace_id: group2.id, note: "group2 issue 2 note 2"
      )

      # associated todos

      # Project issue todo that must not be deleted
      todos.create!(
        target_id: project_issue.id,
        target_type: 'Issue',
        project_id: project.id,
        user_id: user.id,
        author_id: user.id,
        action: 1,
        state: 'pending'
      )

      todos.create!(
        target_id: group1_issue1.id,
        target_type: 'Issue',
        group_id: group1.id,
        user_id: user.id,
        author_id: user.id,
        action: 1,
        state: 'pending'
      )
      todos.create!(
        target_id: group1_issue1.id,
        target_type: 'Issue',
        group_id: group1.id,
        user_id: user.id,
        author_id: user.id,
        action: 1,
        state: 'pending'
      )
      todos.create!(
        target_id: group1_issue2.id,
        target_type: 'Issue',
        group_id: group1.id,
        user_id: user.id,
        author_id: user.id,
        action: 1,
        state: 'pending'
      )
      todos.create!(
        target_id: group1_issue2.id,
        target_type: 'Issue',
        group_id: group1.id,
        user_id: user.id,
        author_id: user.id,
        action: 1,
        state: 'pending'
      )
      todos.create!(
        target_id: group2_issue1.id,
        target_type: 'Issue',
        group_id: group2.id,
        user_id: user.id,
        author_id: user.id,
        action: 1,
        state: 'pending'
      )
      todos.create!(
        target_id: group2_issue1.id,
        target_type: 'Issue',
        group_id: group2.id,
        user_id: user.id,
        author_id: user.id,
        action: 1,
        state: 'pending'
      )
      todos.create!(
        target_id: group2_issue2.id,
        target_type: 'Issue',
        group_id: group2.id,
        user_id: user.id,
        author_id: user.id,
        action: 1,
        state: 'pending'
      )
      todos.create!(
        target_id: group2_issue2.id,
        target_type: 'Issue',
        group_id: group2.id,
        user_id: user.id,
        author_id: user.id,
        action: 1,
        state: 'pending'
      )
    end

    it 'removes group level issues' do
      # We have 1 record of each table that should not be deleted
      expect do
        migrate!
      end.to change { issues.count }.from(5).to(1).and(
        change { label_links.count }.from(9).to(1)
      ).and(
        change { notes.count }.from(9).to(1)
      ).and(
        change { todos.count }.from(9).to(1)
      )
    end
  end

  def ensure_work_item_type_exists
    # We need to make sure at least one work item type exists for this spec and they might have been deleted
    # by other migrations
    work_item_types.find_or_create_by!(
      name: 'Issue', namespace_id: nil, base_type: 0, icon_name: 'issue-type-issue'
    )
  end
end
