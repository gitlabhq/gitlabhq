# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillClustersShardingKey, feature_category: :deployment_management do
  let!(:organization) do
    table(:organizations).create!(id: described_class::DEFAULT_ORGANIZATION_ID, name: 'organization',
      path: 'organization')
  end

  let!(:group1) { table(:namespaces).create!(name: 'group1', path: 'group1', organization_id: organization.id) }
  let!(:group2) { table(:namespaces).create!(name: 'group2', path: 'group2', organization_id: organization.id) }

  let!(:project1) do
    table(:projects).create!(name: 'project1', path: 'project1', namespace_id: group1.id,
      project_namespace_id: group1.id, organization_id: organization.id)
  end

  let!(:project2) do
    table(:projects).create!(name: 'project2', path: 'project2', namespace_id: group2.id,
      project_namespace_id: group2.id, organization_id: organization.id)
  end

  let!(:cluster1) do
    cluster = table(:clusters).create!(name: 'cluster', cluster_type: described_class::PROJECT_TYPE)
    table(:cluster_projects).create!(cluster_id: cluster.id, project_id: project1.id)

    cluster
  end

  let!(:cluster2) do
    cluster = table(:clusters).create!(name: 'cluster', cluster_type: described_class::PROJECT_TYPE)
    table(:cluster_projects).create!(cluster_id: cluster.id, project_id: project2.id)

    cluster
  end

  let!(:cluster3) do
    cluster = table(:clusters).create!(name: 'cluster', cluster_type: described_class::GROUP_TYPE)
    table(:cluster_groups).create!(cluster_id: cluster.id, group_id: group1.id)

    cluster
  end

  let!(:cluster4) do
    cluster = table(:clusters).create!(name: 'cluster', cluster_type: described_class::GROUP_TYPE)
    table(:cluster_groups).create!(cluster_id: cluster.id, group_id: group2.id)

    cluster
  end

  let!(:cluster5) { table(:clusters).create!(name: 'cluster', cluster_type: described_class::INSTANCE_TYPE) }

  let!(:starting_id) { table(:clusters).pluck(:id).min }
  let!(:end_id) { table(:clusters).pluck(:id).max }

  let!(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: :clusters,
      batch_column: :id,
      sub_batch_size: 3,
      pause_ms: 2,
      connection: ::ApplicationRecord.connection
    )
  end

  it 'backfills the missing sharding key' do
    expect(table(:clusters).where(project_id: nil, group_id: nil, organization_id: nil).count).to eq(5)

    migration.perform

    expect(table(:clusters).where(project_id: nil, group_id: nil, organization_id: nil).count).to eq(0)

    expect(cluster1.reload).to have_attributes(
      project_id: project1.id,
      group_id: nil,
      organization_id: nil
    )

    expect(cluster2.reload).to have_attributes(
      project_id: project2.id,
      group_id: nil,
      organization_id: nil
    )

    expect(cluster3.reload).to have_attributes(
      project_id: nil,
      group_id: group1.id,
      organization_id: nil
    )

    expect(cluster4.reload).to have_attributes(
      project_id: nil,
      group_id: group2.id,
      organization_id: nil
    )

    expect(cluster5.reload).to have_attributes(
      project_id: nil,
      group_id: nil,
      organization_id: described_class::DEFAULT_ORGANIZATION_ID
    )
  end
end
