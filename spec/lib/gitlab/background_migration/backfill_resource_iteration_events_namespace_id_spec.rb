# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillResourceIterationEventsNamespaceId, feature_category: :team_planning do
  let(:resource_iteration_events) { table(:resource_iteration_events) }
  let(:iterations) { table(:sprints) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace1) do
    table(:namespaces).create!(name: "group1", path: "group1", organization_id: organization.id)
  end

  let(:namespace2) do
    table(:namespaces).create!(name: "group2", path: "group2", organization_id: organization.id)
  end

  let(:fake_namespace) do
    # Can't create description_versions without a namespace in specs due to the invalid FK already created
    table(:namespaces).create!(id: 0, name: "fake", path: "fake", organization_id: organization.id)
  end

  let(:iteration1) do
    iterations.create!(
      title: 'iteration1',
      group_id: namespace1.id, iid: 1,
      start_date: 1.day.ago,
      due_date: 1.day.from_now
    )
  end

  let(:iteration2) do
    iterations.create!(
      title: 'iteration2',
      group_id: namespace2.id, iid: 1,
      start_date: 1.day.ago,
      due_date: 1.day.from_now
    )
  end

  let(:issue_work_item_type_id) { table(:work_item_types).find_by(name: 'Issue').id }
  let(:issue) do
    table(:issues).create!(
      title: 'First issue',
      iid: 1,
      namespace_id: namespace1.id,
      work_item_type_id: issue_work_item_type_id
    )
  end

  let(:user) { table(:users).create!(username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 2) }

  let!(:issue_resource_event1) do
    resource_iteration_events.create!(
      issue_id: issue.id,
      user_id: user.id,
      action: 1,
      iteration_id: iteration1.id,
      namespace_id: fake_namespace.id
    )
  end

  let!(:issue_resource_event2) do
    resource_iteration_events.create!(
      issue_id: issue.id,
      user_id: user.id,
      action: 1,
      iteration_id: iteration1.id,
      namespace_id: fake_namespace.id
    )
  end

  let!(:issue_resource_event3) do
    resource_iteration_events.create!(
      issue_id: issue.id,
      user_id: user.id,
      action: 1,
      iteration_id: iteration2.id,
      namespace_id: fake_namespace.id
    )
  end

  let!(:issue_resource_event4) do
    resource_iteration_events.create!(
      issue_id: issue.id,
      user_id: user.id,
      action: 1,
      iteration_id: iteration2.id,
      namespace_id: fake_namespace.id
    )
  end

  let(:migration) do
    start_id, end_id = resource_iteration_events.pick('MIN(id), MAX(id)')

    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :resource_iteration_events,
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
      end.to make_queries_matching(/UPDATE\s+"resource_iteration_events"/, 2)
    end

    it 'sets correct namespace_id in every record' do
      expect { migrate }.to change { issue_resource_event1.reload.namespace_id }.from(0).to(namespace1.id).and(
        change { issue_resource_event2.reload.namespace_id }.from(0).to(namespace1.id)
      ).and(
        change { issue_resource_event3.reload.namespace_id }.from(0).to(namespace2.id)
      ).and(
        change { issue_resource_event4.reload.namespace_id }.from(0).to(namespace2.id)
      )
    end
  end
end
