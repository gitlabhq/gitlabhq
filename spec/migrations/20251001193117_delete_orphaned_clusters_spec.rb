# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteOrphanedClusters, feature_category: :deployment_management do
  let(:migration) { described_class.new }

  let(:clusters) { table(:clusters) }
  let!(:project_cluster) { clusters.create!(name: 'cluster', cluster_type: described_class::PROJECT_TYPE) }
  let!(:group_cluster) { clusters.create!(name: 'cluster', cluster_type: described_class::GROUP_TYPE) }
  let!(:instance_cluster) { clusters.create!(name: 'cluster', cluster_type: 1) }

  let!(:orphaned_cluster) { clusters.create!(name: 'cluster', cluster_type: described_class::PROJECT_TYPE) }

  # This should not exist in a real installation,
  # however we want to ensure that records with a
  # project ID already set are ignored
  let!(:orphaned_cluster_with_project_id) do
    clusters.create!(name: 'cluster', cluster_type: described_class::PROJECT_TYPE, project_id: project.id)
  end

  # This should not exist in a real installation,
  # however we want to ensure that records with a
  # group ID already set are ignored
  let!(:orphaned_cluster_with_group_id) do
    clusters.create!(name: 'cluster', cluster_type: described_class::GROUP_TYPE, group_id: group.id)
  end

  let!(:organization) { table(:organizations).create!(path: 'organization') }
  let!(:group) do
    table(:namespaces).create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id)
  end

  let!(:project) do
    table(:projects).create!(name: 'project', namespace_id: group.id, project_namespace_id: group.id,
      organization_id: organization.id)
  end

  let!(:cluster_project) { table(:cluster_projects).create!(cluster_id: project_cluster.id, project_id: project.id) }
  let!(:cluster_group) { table(:cluster_groups).create!(cluster_id: group_cluster.id, group_id: group.id) }

  describe '#up' do
    it 'removes the orphaned cluster record' do
      expect { migration.up }.to change {
        clusters.count
      }.from(6).to(5)

      expect(clusters.where(id: orphaned_cluster.id)).to be_empty
    end
  end

  describe '#down' do
    it 'is a no-op' do
      expect { migration.down }.not_to change {
        clusters.count
      }
    end
  end
end
