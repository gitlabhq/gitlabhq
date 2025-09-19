# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillNamespaceTraversalIdsOnIssues, feature_category: :portfolio_management do
  let(:issues) { table(:issues) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }
  let(:work_item_types) { table(:work_item_types) }

  let(:args) do
    min, max = issues.pick('MIN(id)', 'MAX(id)')

    {
      start_id: min,
      end_id: max,
      batch_table: 'issues',
      batch_column: 'id',
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  let(:issue_type) { work_item_types.find_by!(base_type: 0) } # Issue type
  let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let!(:user) do
    users.create!(username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 1,
      organization_id: organization.id)
  end

  let!(:group_namespace) do
    namespaces.create!(
      organization_id: organization.id,
      name: 'gitlab-org',
      path: 'gitlab-org',
      type: 'Group'
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:other_group_namespace) do
    namespaces.create!(
      organization_id: organization.id,
      name: 'gitlab-com',
      path: 'gitlab-com',
      type: 'Group'
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:issue_1) { create_issues(namespace_id: group_namespace.id) }
  let!(:issue_2) { create_issues(namespace_id: group_namespace.id) }
  let!(:issue_3) { create_issues(namespace_id: other_group_namespace.id) }

  subject(:perform_migration) { described_class.new(**args).perform }

  it 'backfills traversal_ids', :aggregate_failures do
    expect(issue_1.namespace_traversal_ids).to eq([])
    expect(issue_2.namespace_traversal_ids).to eq([])
    expect(issue_3.namespace_traversal_ids).to eq([])

    perform_migration

    expect(issues.find(issue_1.id).namespace_traversal_ids).to eq([group_namespace.id])
    expect(issues.find(issue_2.id).namespace_traversal_ids).to eq([group_namespace.id])
    expect(issues.find(issue_3.id).namespace_traversal_ids).to eq([other_group_namespace.id])
  end

  def create_issues(namespace_id:)
    issues.create!(
      title: 'Issue',
      description: 'Some description',
      namespace_id: namespace_id,
      work_item_type_id: issue_type.id,
      author_id: user.id
    )
  end
end
