# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillClustersKubernetesNamespacesShardingKey, feature_category: :deployment_management do
  include BatchedBackgroundMigrationHelpers::V1::TableHelpers
  tables :organizations, :namespaces, :projects, :clusters, :clusters_kubernetes_namespaces

  let(:connection) { ApplicationRecord.connection }
  let(:function_name) { 'clusters_kubernetes_namespaces_sharding_key' }
  let(:trigger_name) { "trigger_#{function_name}" }
  let(:constraint_name) { 'check_8556b17a2a' }

  let(:organization) { organizations.create!(name: 'name', path: 'path') }
  let(:namespace) { namespaces.create!(name: 'name', path: 'path', organization_id: organization.id) }
  let(:group) do
    namespaces.create!(name: 'test-group', path: 'test-group', type: 'Group', organization_id: organization.id)
  end

  let(:project) do
    projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, organization_id: organization.id)
  end

  let(:cluster_belonging_to_organization) do
    clusters.create!(
      name: 'test-cluster (organization)',
      cluster_type: 1,
      organization_id: organization.id,
      group_id: nil,
      project_id: nil
    )
  end

  let(:cluster_belonging_to_group) do
    clusters.create!(
      name: 'test-cluster (group)',
      cluster_type: 1,
      organization_id: nil,
      group_id: group.id,
      project_id: nil
    )
  end

  let(:cluster_belonging_to_project) do
    clusters.create!(
      name: 'test-cluster (project)',
      cluster_type: 1,
      organization_id: nil,
      group_id: nil,
      project_id: project.id
    )
  end

  let(:kubernetes_namespace_belonging_to_organization_without_sharding_key) do
    clusters_kubernetes_namespaces.create!(
      cluster_id: cluster_belonging_to_organization.id,
      namespace: 'default',
      organization_id: nil,
      group_id: nil,
      sharding_project_id: nil
    )
  end

  let(:kubernetes_namespace_belonging_to_group_without_sharding_key) do
    clusters_kubernetes_namespaces.create!(
      cluster_id: cluster_belonging_to_group.id,
      namespace: 'default',
      organization_id: nil,
      group_id: nil,
      sharding_project_id: nil
    )
  end

  let(:kubernetes_namespace_belonging_to_project_without_sharding_key) do
    clusters_kubernetes_namespaces.create!(
      cluster_id: cluster_belonging_to_project.id,
      namespace: 'default',
      organization_id: nil,
      group_id: nil,
      sharding_project_id: nil
    )
  end

  let(:kubernetes_namespace_belonging_to_organization_with_all_sharding_key_columns) do
    clusters_kubernetes_namespaces.create!(
      cluster_id: cluster_belonging_to_organization.id,
      namespace: 'default',
      organization_id: organization.id,
      group_id: group.id,
      sharding_project_id: project.id
    )
  end

  let(:kubernetes_namespace_belonging_to_group_with_all_sharding_key_columns) do
    clusters_kubernetes_namespaces.create!(
      cluster_id: cluster_belonging_to_group.id,
      namespace: 'default',
      organization_id: organization.id,
      group_id: group.id,
      sharding_project_id: project.id
    )
  end

  let(:kubernetes_namespace_belonging_to_project_with_all_sharding_key_columns) do
    clusters_kubernetes_namespaces.create!(
      cluster_id: cluster_belonging_to_project.id,
      namespace: 'default',
      organization_id: organization.id,
      group_id: group.id,
      sharding_project_id: project.id
    )
  end

  let(:kubernetes_namespace_belonging_to_organization_with_valid_sharding_key) do
    clusters_kubernetes_namespaces.create!(
      cluster_id: cluster_belonging_to_organization.id,
      namespace: 'default',
      organization_id: organization.id,
      group_id: nil,
      sharding_project_id: nil
    )
  end

  let(:kubernetes_namespace_belonging_to_group_with_valid_sharding_key) do
    clusters_kubernetes_namespaces.create!(
      cluster_id: cluster_belonging_to_group.id,
      namespace: 'default',
      organization_id: nil,
      group_id: group.id,
      sharding_project_id: nil
    )
  end

  let(:kubernetes_namespace_belonging_to_project_with_valid_sharding_key) do
    clusters_kubernetes_namespaces.create!(
      cluster_id: cluster_belonging_to_project.id,
      namespace: 'default',
      organization_id: nil,
      group_id: nil,
      sharding_project_id: project.id
    )
  end

  subject(:migration) do
    described_class.new(
      start_id: clusters_kubernetes_namespaces.minimum(:id),
      end_id: clusters_kubernetes_namespaces.maximum(:id),
      batch_table: :clusters_kubernetes_namespaces,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: connection
    )
  end

  before do
    migration_context.down(20260108175602)
  end

  describe "#perform" do
    it 'backfills sharding key for records belonging to an organization that do not have it' do
      kubernetes_namespace_belonging_to_organization_without_sharding_key.reload
      expect(kubernetes_namespace_belonging_to_organization_without_sharding_key.organization_id).to be_nil
      expect(kubernetes_namespace_belonging_to_organization_without_sharding_key.group_id).to be_nil
      expect(kubernetes_namespace_belonging_to_organization_without_sharding_key.sharding_project_id).to be_nil

      migration.perform

      kubernetes_namespace_belonging_to_organization_without_sharding_key.reload
      expect(kubernetes_namespace_belonging_to_organization_without_sharding_key.organization_id).to eq(organization.id)
      expect(kubernetes_namespace_belonging_to_organization_without_sharding_key.group_id).to be_nil
      expect(kubernetes_namespace_belonging_to_organization_without_sharding_key.sharding_project_id).to be_nil
    end

    it 'backfills sharding key for records belonging to a group that do not have it' do
      kubernetes_namespace_belonging_to_group_without_sharding_key.reload
      expect(kubernetes_namespace_belonging_to_group_without_sharding_key.organization_id).to be_nil
      expect(kubernetes_namespace_belonging_to_group_without_sharding_key.group_id).to be_nil
      expect(kubernetes_namespace_belonging_to_group_without_sharding_key.sharding_project_id).to be_nil

      migration.perform

      kubernetes_namespace_belonging_to_group_without_sharding_key.reload
      expect(kubernetes_namespace_belonging_to_group_without_sharding_key.organization_id).to be_nil
      expect(kubernetes_namespace_belonging_to_group_without_sharding_key.group_id).to eq(group.id)
      expect(kubernetes_namespace_belonging_to_group_without_sharding_key.sharding_project_id).to be_nil
    end

    it 'backfills sharding key for records belonging to a project that do not have it' do
      kubernetes_namespace_belonging_to_project_without_sharding_key.reload
      expect(kubernetes_namespace_belonging_to_project_without_sharding_key.organization_id).to be_nil
      expect(kubernetes_namespace_belonging_to_project_without_sharding_key.group_id).to be_nil
      expect(kubernetes_namespace_belonging_to_project_without_sharding_key.sharding_project_id).to be_nil

      migration.perform

      kubernetes_namespace_belonging_to_project_without_sharding_key.reload
      expect(kubernetes_namespace_belonging_to_project_without_sharding_key.organization_id).to be_nil
      expect(kubernetes_namespace_belonging_to_project_without_sharding_key.group_id).to be_nil
      expect(kubernetes_namespace_belonging_to_project_without_sharding_key.sharding_project_id).to eq(project.id)
    end

    it 'backfills sharding key for records belonging to an organization that have multiple sharding key columns set' do
      kubernetes_namespace_belonging_to_organization_with_all_sharding_key_columns.reload
      expect(kubernetes_namespace_belonging_to_organization_with_all_sharding_key_columns.organization_id)
        .to eq(organization.id)
      expect(kubernetes_namespace_belonging_to_organization_with_all_sharding_key_columns.group_id).to eq(group.id)
      expect(kubernetes_namespace_belonging_to_organization_with_all_sharding_key_columns.sharding_project_id)
        .to eq(project.id)

      migration.perform

      kubernetes_namespace_belonging_to_organization_with_all_sharding_key_columns.reload
      expect(kubernetes_namespace_belonging_to_organization_with_all_sharding_key_columns.organization_id)
        .to eq(organization.id)
      expect(kubernetes_namespace_belonging_to_organization_with_all_sharding_key_columns.group_id).to be_nil
      expect(kubernetes_namespace_belonging_to_organization_with_all_sharding_key_columns.sharding_project_id).to be_nil
    end

    it 'backfills sharding key for records belonging to a group that have multiple sharding key columns set' do
      kubernetes_namespace_belonging_to_group_with_all_sharding_key_columns.reload
      expect(kubernetes_namespace_belonging_to_group_with_all_sharding_key_columns.organization_id)
        .to eq(organization.id)
      expect(kubernetes_namespace_belonging_to_group_with_all_sharding_key_columns.group_id).to eq(group.id)
      expect(kubernetes_namespace_belonging_to_group_with_all_sharding_key_columns.sharding_project_id)
        .to eq(project.id)

      migration.perform

      kubernetes_namespace_belonging_to_group_with_all_sharding_key_columns.reload
      expect(kubernetes_namespace_belonging_to_group_with_all_sharding_key_columns.organization_id).to be_nil
      expect(kubernetes_namespace_belonging_to_group_with_all_sharding_key_columns.group_id).to eq(group.id)
      expect(kubernetes_namespace_belonging_to_group_with_all_sharding_key_columns.sharding_project_id).to be_nil
    end

    it 'backfills sharding key for records belonging to a project that have multiple sharding key columns set' do
      kubernetes_namespace_belonging_to_project_with_all_sharding_key_columns.reload
      expect(kubernetes_namespace_belonging_to_project_with_all_sharding_key_columns.organization_id)
        .to eq(organization.id)
      expect(kubernetes_namespace_belonging_to_project_with_all_sharding_key_columns.group_id).to eq(group.id)
      expect(kubernetes_namespace_belonging_to_project_with_all_sharding_key_columns.sharding_project_id)
        .to eq(project.id)

      migration.perform

      kubernetes_namespace_belonging_to_project_with_all_sharding_key_columns.reload
      expect(kubernetes_namespace_belonging_to_project_with_all_sharding_key_columns.organization_id).to be_nil
      expect(kubernetes_namespace_belonging_to_project_with_all_sharding_key_columns.group_id).to be_nil
      expect(kubernetes_namespace_belonging_to_project_with_all_sharding_key_columns.sharding_project_id)
        .to eq(project.id)
    end

    it 'does not modify records belonging to an organization that already have a valid sharding key' do
      kubernetes_namespace_belonging_to_organization_with_valid_sharding_key.reload
      expect(kubernetes_namespace_belonging_to_organization_with_valid_sharding_key.organization_id)
        .to eq(organization.id)
      expect(kubernetes_namespace_belonging_to_organization_with_valid_sharding_key.group_id).to be_nil
      expect(kubernetes_namespace_belonging_to_organization_with_valid_sharding_key.sharding_project_id).to be_nil

      migration.perform

      kubernetes_namespace_belonging_to_organization_with_valid_sharding_key.reload
      expect(kubernetes_namespace_belonging_to_organization_with_valid_sharding_key.organization_id)
        .to eq(organization.id)
      expect(kubernetes_namespace_belonging_to_organization_with_valid_sharding_key.group_id).to be_nil
      expect(kubernetes_namespace_belonging_to_organization_with_valid_sharding_key.sharding_project_id).to be_nil
    end

    it 'does not modify records belonging to a group that already have a valid sharding key' do
      kubernetes_namespace_belonging_to_group_with_valid_sharding_key.reload
      expect(kubernetes_namespace_belonging_to_group_with_valid_sharding_key.organization_id).to be_nil
      expect(kubernetes_namespace_belonging_to_group_with_valid_sharding_key.group_id).to eq(group.id)
      expect(kubernetes_namespace_belonging_to_group_with_valid_sharding_key.sharding_project_id).to be_nil

      migration.perform

      kubernetes_namespace_belonging_to_group_with_valid_sharding_key.reload
      expect(kubernetes_namespace_belonging_to_group_with_valid_sharding_key.organization_id).to be_nil
      expect(kubernetes_namespace_belonging_to_group_with_valid_sharding_key.group_id).to eq(group.id)
      expect(kubernetes_namespace_belonging_to_group_with_valid_sharding_key.sharding_project_id).to be_nil
    end

    it 'does not modify records belonging to a project that already have a valid sharding key' do
      kubernetes_namespace_belonging_to_project_with_valid_sharding_key.reload
      expect(kubernetes_namespace_belonging_to_project_with_valid_sharding_key.organization_id).to be_nil
      expect(kubernetes_namespace_belonging_to_project_with_valid_sharding_key.group_id).to be_nil
      expect(kubernetes_namespace_belonging_to_project_with_valid_sharding_key.sharding_project_id).to eq(project.id)

      migration.perform

      kubernetes_namespace_belonging_to_project_with_valid_sharding_key.reload
      expect(kubernetes_namespace_belonging_to_project_with_valid_sharding_key.organization_id).to be_nil
      expect(kubernetes_namespace_belonging_to_project_with_valid_sharding_key.group_id).to be_nil
      expect(kubernetes_namespace_belonging_to_project_with_valid_sharding_key.sharding_project_id).to eq(project.id)
    end
  end
end
