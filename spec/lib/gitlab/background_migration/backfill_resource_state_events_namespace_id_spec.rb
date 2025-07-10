# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillResourceStateEventsNamespaceId, feature_category: :team_planning do
  let(:resource_state_events) { table(:resource_state_events) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:project_namespace) do
    table(:namespaces).create!(name: "project1", path: "project1", organization_id: organization.id)
  end

  let(:issue_namespace) do
    table(:namespaces).create!(name: "group1", path: "group1", organization_id: organization.id)
  end

  let(:epic_namespace) do
    table(:namespaces).create!(name: "group1", path: "group1", organization_id: organization.id)
  end

  let(:fake_namespace) do
    # Can't create resource_state_events without a namespace in specs due to the invalid FK
    table(:namespaces).create!(id: 0, name: "fake", path: "fake", organization_id: organization.id)
  end

  let(:project) do
    table(:projects).create!(
      namespace_id: project_namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  let(:merge_request) do
    table(:merge_requests).create!(target_project_id: project.id, target_branch: 'main', source_branch: 'not-main')
  end

  let(:issue_work_item_type_id) { 1 }
  let(:issue) do
    table(:issues).create!(
      title: 'First issue',
      iid: 1,
      namespace_id: issue_namespace.id,
      work_item_type_id: issue_work_item_type_id
    )
  end

  let(:user) { table(:users).create!(username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 2) }
  let(:epic) do
    table(:epics).create!(
      iid: 1,
      group_id: epic_namespace.id,
      author_id: user.id,
      title: 't',
      title_html: 't',
      issue_id: issue.id
    )
  end

  let!(:issue_state_event1) do
    resource_state_events.create!(
      issue_id: issue.id,
      state: 1,
      user_id: user.id,
      namespace_id: fake_namespace.id
    )
  end

  let!(:issue_state_event2) do
    resource_state_events.create!(
      issue_id: issue.id,
      state: 1,
      user_id: user.id,
      namespace_id: fake_namespace.id
    )
  end

  let!(:mr_state_event1) do
    resource_state_events.create!(
      merge_request_id: merge_request.id,
      state: 1,
      user_id: user.id,
      namespace_id: fake_namespace.id
    )
  end

  let!(:mr_state_event2) do
    resource_state_events.create!(
      merge_request_id: merge_request.id,
      state: 1,
      user_id: user.id,
      namespace_id: fake_namespace.id
    )
  end

  let!(:epic_state_event1) do
    resource_state_events.create!(
      epic_id: epic.id,
      state: 1,
      user_id: user.id,
      namespace_id: fake_namespace.id
    )
  end

  let!(:epic_state_event2) do
    resource_state_events.create!(
      epic_id: epic.id,
      state: 1,
      user_id: user.id,
      namespace_id: fake_namespace.id
    )
  end

  let(:migration) do
    start_id, end_id = resource_state_events.pick('MIN(id), MAX(id)')

    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :resource_state_events,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      job_arguments: [],
      connection: ApplicationRecord.connection
    )
  end

  subject(:migrate) { migration.perform }

  describe '#up' do
    it 'updates records in batches' do
      expect do
        migrate
      end.to make_queries_matching(/UPDATE\s+"resource_state_events"/, 9) # 3 updates per batch
    end

    it 'sets correct namespace_id in every record' do
      expect { migrate }.to change { issue_state_event1.reload.namespace_id }.from(0).to(issue_namespace.id).and(
        change { issue_state_event2.reload.namespace_id }.from(0).to(issue_namespace.id)
      ).and(
        change { mr_state_event1.reload.namespace_id }.from(0).to(project_namespace.id)
      ).and(
        change { mr_state_event2.reload.namespace_id }.from(0).to(project_namespace.id)
      ).and(
        change { epic_state_event1.reload.namespace_id }.from(0).to(epic_namespace.id)
      ).and(
        change { epic_state_event2.reload.namespace_id }.from(0).to(epic_namespace.id)
      )
    end
  end
end
