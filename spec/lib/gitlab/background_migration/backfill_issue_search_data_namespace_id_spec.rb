# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIssueSearchDataNamespaceId,
  schema: 20231220225325, feature_category: :team_planning do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:issues) { table(:issues) }
  let(:issue_search_data) { table(:issue_search_data) }
  let(:issue_type) { table(:work_item_types).find_by!(namespace_id: nil, base_type: 0) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let(:namespace_1) do
    namespaces
      .create!(name: 'namespace1', type: 'Group', path: 'namespace1', organization_id: organization.id)
  end

  let(:namespace_2) do
    namespaces
      .create!(name: 'namespace2', type: 'Group', path: 'namespace2', organization_id: organization.id)
  end

  let(:proj_ns_1) do
    namespaces.create!(
      name: 'pn1',
      path: 'pn1',
      type: 'Project',
      parent_id: namespace_1.id,
      organization_id: organization.id
    )
  end

  let(:proj_ns_2) do
    namespaces.create!(
      name: 'pn2',
      path: 'pn2',
      type: 'Project',
      parent_id: namespace_2.id,
      organization_id: organization.id
    )
  end

  let(:proj_1) do
    projects.create!(
      name: 'proj1',
      path: 'proj1',
      namespace_id: namespace_1.id,
      project_namespace_id: proj_ns_1.id,
      organization_id: organization.id
    )
  end

  let(:proj_2) do
    projects.create!(
      name: 'proj2',
      path: 'proj2',
      namespace_id: namespace_2.id,
      project_namespace_id: proj_ns_2.id,
      organization_id: organization.id
    )
  end

  let(:proj_1_issue_1) do
    issues.create!(title: 'issue1', project_id: proj_1.id, namespace_id: proj_ns_1.id, work_item_type_id: issue_type.id)
  end

  let(:proj_1_issue_2) do
    issues.create!(title: 'issue2', project_id: proj_1.id, namespace_id: proj_ns_1.id, work_item_type_id: issue_type.id)
  end

  let(:proj_2_issue_1) do
    issues.create!(title: 'issue1', project_id: proj_2.id, namespace_id: proj_ns_2.id, work_item_type_id: issue_type.id)
  end

  let(:proj_2_issue_2) do
    issues.create!(title: 'issue2', project_id: proj_2.id, namespace_id: proj_ns_2.id, work_item_type_id: issue_type.id)
  end

  let!(:proj_1_issue_1_search_data) do
    issue_search_data.create!(namespace_id: nil, project_id: proj_1.id, issue_id: proj_1_issue_1.id)
  end

  let!(:proj_1_issue_2_search_data) do
    issue_search_data.create!(namespace_id: nil, project_id: proj_1.id, issue_id: proj_1_issue_2.id)
  end

  let!(:proj_2_issue_1_search_data) do
    issue_search_data.create!(namespace_id: nil, project_id: proj_2.id, issue_id: proj_2_issue_1.id)
  end

  let!(:proj_2_issue_2_search_data) do
    issue_search_data.create!(namespace_id: nil, project_id: proj_2.id, issue_id: proj_2_issue_2.id)
  end

  let(:migration) do
    described_class.new(
      start_id: proj_1_issue_1.id,
      end_id: proj_2_issue_2.id,
      batch_table: :issues,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 2,
      connection: ApplicationRecord.connection
    )
  end

  it 'backfills namespace_id for the specified records' do
    migration.perform

    [proj_1_issue_1, proj_1_issue_2, proj_2_issue_1, proj_2_issue_2].each do |issue|
      expect(issue_search_data.find_by_issue_id(issue.id).namespace_id).to eq(issue.namespace_id)
    end
  end
end
