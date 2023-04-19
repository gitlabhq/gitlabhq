# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BulkInsertClusterEnabledGrants, :migration, feature_category: :deployment_management do
  let(:migration) { described_class.new }

  let(:cluster_enabled_grants) { table(:cluster_enabled_grants) }
  let(:namespaces) { table(:namespaces) }
  let(:cluster_projects) { table(:cluster_projects) }
  let(:cluster_groups) { table(:cluster_groups) }
  let(:clusters) { table(:clusters) }
  let(:projects) { table(:projects) }

  context 'with namespaces, cluster_groups and cluster_projects' do
    it 'creates unique cluster_enabled_grants for root_namespaces with clusters' do
      # Does not create grants for namespaces without clusters
      namespaces.create!(id: 1, path: 'eee', name: 'eee', traversal_ids: [1]) # not used

      # Creates unique grant for a root namespace with its own cluster
      root_ns_with_own_cluster = namespaces.create!(id: 2, path: 'ddd', name: 'ddd', traversal_ids: [2])
      cluster_root_ns_with_own_cluster = clusters.create!(name: 'cluster_root_ns_with_own_cluster')
      cluster_groups.create!(
        cluster_id: cluster_root_ns_with_own_cluster.id,
        group_id: root_ns_with_own_cluster.id)

      # Creates unique grant for namespaces with multiple sub-group clusters
      root_ns_with_sub_group_clusters = namespaces.create!(id: 3, path: 'aaa', name: 'aaa', traversal_ids: [3])

      subgroup_1 = namespaces.create!(
        id: 4,
        path: 'bbb',
        name: 'bbb',
        parent_id: root_ns_with_sub_group_clusters.id,
        traversal_ids: [root_ns_with_sub_group_clusters.id, 4])
      cluster_subgroup_1 = clusters.create!(name: 'cluster_subgroup_1')
      cluster_groups.create!(cluster_id: cluster_subgroup_1.id, group_id: subgroup_1.id)

      subgroup_2 = namespaces.create!(
        id: 5,
        path: 'ccc',
        name: 'ccc',
        parent_id: subgroup_1.id,
        traversal_ids: [root_ns_with_sub_group_clusters.id, subgroup_1.id, 5])
      cluster_subgroup_2 = clusters.create!(name: 'cluster_subgroup_2')
      cluster_groups.create!(cluster_id: cluster_subgroup_2.id, group_id: subgroup_2.id)

      # Creates unique grant for a root namespace with multiple projects clusters
      root_ns_with_project_group_clusters = namespaces.create!(id: 6, path: 'fff', name: 'fff', traversal_ids: [6])

      project_namespace_1 = namespaces.create!(id: 7, path: 'ggg', name: 'ggg', traversal_ids: [7])
      project_1 = projects.create!(
        name: 'project_1',
        namespace_id: root_ns_with_project_group_clusters.id,
        project_namespace_id: project_namespace_1.id)
      cluster_project_1 = clusters.create!(name: 'cluster_project_1')
      cluster_projects.create!(cluster_id: cluster_project_1.id, project_id: project_1.id)

      project_namespace_2 = namespaces.create!(id: 8, path: 'hhh', name: 'hhh', traversal_ids: [8])
      project_2 = projects.create!(
        name: 'project_2',
        namespace_id: root_ns_with_project_group_clusters.id,
        project_namespace_id: project_namespace_2.id)
      cluster_project_2 = clusters.create!(name: 'cluster_project_2')
      cluster_projects.create!(cluster_id: cluster_project_2.id, project_id: project_2.id)

      migrate!

      expected_cluster_enabled_grants = [
        root_ns_with_sub_group_clusters.id,
        root_ns_with_own_cluster.id,
        root_ns_with_project_group_clusters.id
      ]

      expect(cluster_enabled_grants.pluck(:namespace_id)).to match_array(expected_cluster_enabled_grants)
    end
  end

  context 'without namespaces, cluster_groups or cluster_projects' do
    it 'does nothing' do
      expect { migrate! }.not_to change { cluster_enabled_grants.count }
    end
  end
end
