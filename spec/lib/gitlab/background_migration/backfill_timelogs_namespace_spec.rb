# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillTimelogsNamespace, feature_category: :team_planning do
  let(:timelogs) { table(:timelogs) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:project_namespace) do
    table(:namespaces).create!(name: "project1", path: "project1", organization_id: organization.id)
  end

  let(:group_namespace) do
    table(:namespaces).create!(name: "group1", path: "group1", organization_id: organization.id)
  end

  let(:fake_namespace) do
    # Can't create timelogs without a namespace in specs due to the invalid FK
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

  let(:issue_work_item_type_id) { table(:work_item_types).find_by(name: 'Issue').id }

  let(:issue) do
    table(:issues).create!(
      title: 'First issue',
      iid: 1,
      namespace_id: group_namespace.id,
      work_item_type_id: issue_work_item_type_id
    )
  end

  let(:user) do
    table(:users).create!(username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 10,
      organization_id: organization.id)
  end

  let!(:issue_timelog1) do
    timelogs.create!(
      issue_id: issue.id,
      user_id: user.id,
      time_spent: 3600,
      namespace_id: fake_namespace.id
    )
  end

  let!(:issue_timelog2) do
    timelogs.create!(
      issue_id: issue.id,
      user_id: user.id,
      time_spent: 3600,
      namespace_id: fake_namespace.id
    )
  end

  let!(:merge_request_timelog1) do
    timelogs.create!(
      merge_request_id: merge_request.id,
      user_id: user.id,
      time_spent: 3600,
      namespace_id: fake_namespace.id
    )
  end

  let!(:merge_request_timelog2) do
    timelogs.create!(
      merge_request_id: merge_request.id,
      user_id: user.id,
      time_spent: 3600,
      namespace_id: fake_namespace.id
    )
  end

  let(:migration) do
    start_id, end_id = timelogs.pick('MIN(id), MAX(id)')

    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :timelogs,
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
      end.to make_queries_matching(/UPDATE\s+"timelogs"/, 4) # 2 updates per batch
    end

    it 'sets correct namespace_id in every record' do
      expect { migrate }.to change { issue_timelog1.reload.namespace_id }.from(0).to(group_namespace.id).and(
        change { issue_timelog2.reload.namespace_id }.from(0).to(group_namespace.id)
      ).and(
        change { merge_request_timelog1.reload.namespace_id }.from(0).to(project_namespace.id)
      ).and(
        change { merge_request_timelog2.reload.namespace_id }.from(0).to(project_namespace.id)
      )
    end
  end
end
