# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIssueAssigneesNamespaceId, feature_category: :team_planning do
  let(:connection) { ApplicationRecord.connection }
  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:user_1) do
    users.create!(user_type: 0, username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 10)
  end

  let(:start_cursor) { [0, 0] }
  let(:end_cursor) { [issues.maximum(:id), 0] }

  let(:migration) do
    described_class.new(
      start_cursor: start_cursor,
      end_cursor: end_cursor,
      batch_table: :issue_assignees,
      batch_column: :issue_id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: connection
    )
  end

  shared_context 'for database tables' do
    let(:namespaces) { table(:namespaces) }
    let(:organizations) { table(:organizations) }
    let(:issues) { table(:issues) { |t| t.primary_key = :id } }
    let(:issue_assignees) { table(:issue_assignees) { |t| t.primary_key = :issue_id } }
    let(:users) { table(:users) }
    let(:projects) { table(:projects) }
  end

  shared_context 'for namespaces' do
    let(:namespace1) { namespaces.create!(name: 'namespace 1', path: 'namespace1', organization_id: organization.id) }
    let(:namespace2) { namespaces.create!(name: 'namespace 2', path: 'namespace2', organization_id: organization.id) }
    let(:namespace3) { namespaces.create!(name: 'namespace 3', path: 'namespace3', organization_id: organization.id) }
    let(:namespace4) { namespaces.create!(name: 'namespace 4', path: 'namespace4', organization_id: organization.id) }
    let(:namespace5) { namespaces.create!(name: 'namespace 5', path: 'namespace5', organization_id: organization.id) }
  end

  shared_context 'for projects' do
    let(:project1) do
      projects.create!(
        namespace_id: namespace1.id,
        project_namespace_id: namespace1.id,
        organization_id: organization.id
      )
    end

    let(:project2) do
      projects.create!(
        namespace_id: namespace2.id,
        project_namespace_id: namespace2.id,
        organization_id: organization.id
      )
    end

    let(:project3) do
      projects.create!(
        namespace_id: namespace3.id,
        project_namespace_id: namespace3.id,
        organization_id: organization.id
      )
    end

    let(:project4) do
      projects.create!(
        namespace_id: namespace4.id,
        project_namespace_id: namespace4.id,
        organization_id: organization.id
      )
    end
  end

  shared_context 'for issues and assignees' do
    let!(:work_item_type_id) { table(:work_item_types).where(base_type: 1).first.id }

    let!(:issue1) do
      issues.create!(
        namespace_id: namespace1.id,
        project_id: project1.id,
        created_at: 5.days.ago,
        closed_at: 3.days.ago,
        work_item_type_id: work_item_type_id
      )
    end

    let!(:issue2) do
      issues.create!(
        namespace_id: namespace2.id,
        project_id: project2.id,
        created_at: 4.days.ago,
        closed_at: 3.days.ago,
        work_item_type_id: work_item_type_id
      )
    end

    let!(:issue3) do
      issues.create!(
        namespace_id: namespace3.id,
        project_id: project3.id,
        created_at: 3.days.ago,
        closed_at: 2.days.ago,
        work_item_type_id: work_item_type_id
      )
    end

    let!(:issue4) do
      issues.create!(
        namespace_id: namespace4.id,
        project_id: project4.id,
        created_at: 2.days.ago,
        closed_at: 2.days.ago,
        work_item_type_id: work_item_type_id
      )
    end

    let!(:issue_assignee_1) { issue_assignees.create!(issue_id: issue1.id, user_id: user_1.id, namespace_id: nil) }
    let!(:issue_assignee_2) { issue_assignees.create!(issue_id: issue2.id, user_id: user_1.id, namespace_id: nil) }
    let!(:issue_assignee_3) { issue_assignees.create!(issue_id: issue3.id, user_id: user_1.id, namespace_id: nil) }
    let!(:issue_assignee_4) do
      issue_assignees.create!(issue_id: issue4.id, user_id: user_1.id, namespace_id: namespace5.id)
    end
  end

  include_context 'for database tables'
  include_context 'for namespaces'
  include_context 'for projects'
  include_context 'for issues and assignees'

  describe '#perform' do
    it 'backfills issue_assignees.namespace_id correctly for relevant records' do
      migration.perform

      expect(issue_assignee_1.reload.namespace_id).to eq(issue1.namespace_id)
      expect(issue_assignee_2.reload.namespace_id).to eq(issue2.namespace_id)
      expect(issue_assignee_3.reload.namespace_id).to eq(issue3.namespace_id)
    end

    it 'does not update issue_assignees with pre-existing namespace_id' do
      expect { migration.perform }
        .not_to change { issue_assignee_4.reload.namespace_id }
    end
  end
end
