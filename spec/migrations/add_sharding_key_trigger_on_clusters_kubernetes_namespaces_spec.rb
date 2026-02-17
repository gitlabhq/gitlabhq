# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddShardingKeyTriggerOnClustersKubernetesNamespaces, feature_category: :deployment_management do
  include BatchedBackgroundMigrationHelpers::V1::TableHelpers
  tables :organizations, :namespaces, :projects, :clusters, :clusters_kubernetes_namespaces

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }
  let(:group) do
    namespaces.create!(name: 'test-group', path: 'test-group', type: 'Group', organization_id: organization.id)
  end

  let(:project) do
    projects.create!(name: 'project', path: 'project', project_namespace_id: namespace.id, namespace_id: namespace.id,
      organization_id: organization.id)
  end

  let(:cluster_with_organization_id) do
    clusters.create!(name: 'cluster1', cluster_type: 1, organization_id: organization.id)
  end

  let(:cluster_with_group_id) do
    clusters.create!(name: 'cluster_with_group_id', cluster_type: 1, group_id: group.id)
  end

  let(:cluster_with_project_id) do
    clusters.create!(name: 'cluster_with_project_id', cluster_type: 1, project_id: project.id)
  end

  describe '#up' do
    context 'when inserting new records' do
      it 'sets sharding key columns from the parent clusters table' do
        migrate!

        kube_namespace1 = clusters_kubernetes_namespaces.create!(cluster_id: cluster_with_organization_id.id,
          namespace: 'namespace1', organization_id: nil, group_id: nil, sharding_project_id: nil)
        kube_namespace2 = clusters_kubernetes_namespaces.create!(cluster_id: cluster_with_group_id.id,
          namespace: 'namespace2', organization_id: nil, group_id: nil, sharding_project_id: nil)
        kube_namespace3 = clusters_kubernetes_namespaces.create!(cluster_id: cluster_with_project_id.id,
          namespace: 'namespace3', organization_id: nil, group_id: nil, sharding_project_id: nil)

        kube_namespace1.reload
        expect(kube_namespace1.organization_id).to eq(organization.id)
        expect(kube_namespace1.group_id).to be_nil
        expect(kube_namespace1.sharding_project_id).to be_nil

        kube_namespace2.reload
        expect(kube_namespace2.organization_id).to be_nil
        expect(kube_namespace2.group_id).to eq(group.id)
        expect(kube_namespace2.sharding_project_id).to be_nil

        kube_namespace3.reload
        expect(kube_namespace3.organization_id).to be_nil
        expect(kube_namespace3.group_id).to be_nil
        expect(kube_namespace3.sharding_project_id).to eq(project.id)
      end
    end

    context 'when updating existing records' do
      it 'sets sharding key columns when updating a record without them' do
        migration_context.down(20260108175602)

        kube_namespace1 = clusters_kubernetes_namespaces.create!(cluster_id: cluster_with_organization_id.id,
          namespace: 'namespace1', organization_id: nil, group_id: nil, sharding_project_id: nil)
        kube_namespace1.reload
        expect(kube_namespace1.organization_id).to be_nil
        expect(kube_namespace1.group_id).to be_nil
        expect(kube_namespace1.sharding_project_id).to be_nil

        kube_namespace2 = clusters_kubernetes_namespaces.create!(cluster_id: cluster_with_group_id.id,
          namespace: 'namespace2', organization_id: nil, group_id: nil, sharding_project_id: nil)
        kube_namespace2.reload
        expect(kube_namespace2.organization_id).to be_nil
        expect(kube_namespace2.group_id).to be_nil
        expect(kube_namespace2.sharding_project_id).to be_nil

        kube_namespace3 = clusters_kubernetes_namespaces.create!(cluster_id: cluster_with_project_id.id,
          namespace: 'namespace3', organization_id: nil, group_id: nil, sharding_project_id: nil)
        kube_namespace3.reload
        expect(kube_namespace3.organization_id).to be_nil
        expect(kube_namespace3.group_id).to be_nil
        expect(kube_namespace3.sharding_project_id).to be_nil

        migrate!

        # Update the record to trigger the function
        kube_namespace1.update!(namespace: 'namespace1_updated')
        kube_namespace1.reload

        expect(kube_namespace1.organization_id).to eq(organization.id)
        expect(kube_namespace1.group_id).to be_nil
        expect(kube_namespace1.sharding_project_id).to be_nil

        # Update the record to trigger the function
        kube_namespace2.update!(namespace: 'namespace2_updated')
        kube_namespace2.reload

        expect(kube_namespace2.organization_id).to be_nil
        expect(kube_namespace2.group_id).to eq(group.id)
        expect(kube_namespace2.sharding_project_id).to be_nil

        # Update the record to trigger the function
        kube_namespace3.update!(namespace: 'namespace3_updated')
        kube_namespace3.reload

        expect(kube_namespace3.organization_id).to be_nil
        expect(kube_namespace3.group_id).to be_nil
        expect(kube_namespace3.sharding_project_id).to eq(project.id)
      end
    end
  end
end
