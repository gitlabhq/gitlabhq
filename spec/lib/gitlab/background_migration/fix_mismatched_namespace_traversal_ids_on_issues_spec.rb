# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixMismatchedNamespaceTraversalIdsOnIssues,
  feature_category: :portfolio_management do
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

  let(:issue_type_id) { 1 }
  let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let!(:user) do
    users.create!(username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 1,
      organization_id: organization.id)
  end

  let!(:namespace) do
    namespaces.create!(
      organization_id: organization.id,
      name: 'gitlab-org',
      path: 'gitlab-org',
      type: 'Group'
    ).tap { |ns| ns.update!(traversal_ids: [ns.id]) }
  end

  let!(:other_namespace) do
    namespaces.create!(
      organization_id: organization.id,
      name: 'gitlab-com',
      path: 'gitlab-com',
      type: 'Group'
    ).tap { |ns| ns.update!(traversal_ids: [ns.id]) }
  end

  let!(:issue_with_mismatch) { create_issue(namespace_id: namespace.id) }
  let!(:issue_correct) { create_issue(namespace_id: namespace.id) }
  let!(:issue_other_namespace_mismatch) { create_issue(namespace_id: other_namespace.id) }

  subject(:perform_migration) { described_class.new(**args).perform }

  before do
    # Set up mismatched traversal_ids: issues have stale values, namespaces have correct ones
    issue_with_mismatch.update_column(:namespace_traversal_ids, [999, 888])
    issue_correct.update_column(:namespace_traversal_ids, namespace.traversal_ids)
    issue_other_namespace_mismatch.update_column(:namespace_traversal_ids, [777])
  end

  it 'fixes only issues with mismatched namespace_traversal_ids', :aggregate_failures do
    perform_migration

    expect(issues.find(issue_with_mismatch.id).namespace_traversal_ids)
      .to eq(namespace.traversal_ids)
    expect(issues.find(issue_correct.id).namespace_traversal_ids)
      .to eq(namespace.traversal_ids)
    expect(issues.find(issue_other_namespace_mismatch.id).namespace_traversal_ids)
      .to eq(other_namespace.traversal_ids)
  end

  it 'does not update issues that already have correct namespace_traversal_ids' do
    expect { perform_migration }
      .not_to change { issues.find(issue_correct.id).namespace_traversal_ids }
  end

  def create_issue(namespace_id:)
    issues.create!(
      title: 'Issue',
      description: 'Some description',
      namespace_id: namespace_id,
      work_item_type_id: issue_type_id,
      author_id: user.id
    )
  end
end
