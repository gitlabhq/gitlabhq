# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillClusterProvidersGcpShardingKey, feature_category: :deployment_management do
  let(:connection) { ApplicationRecord.connection }

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:clusters) { table(:clusters) }
  let(:cluster_providers_gcp) { table(:cluster_providers_gcp) }

  let(:function_name) { 'cluster_providers_gcp_sharding_key' }
  let(:trigger_name) { "trigger_#{function_name}" }
  let(:constraint_name) { 'check_a92783b0a9' }

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
      name: 'test-cluster',
      cluster_type: 1,
      organization_id: organization.id,
      group_id: nil,
      project_id: nil
    )
  end

  let(:provider_without_sharding_key) do
    drop_constraint_and_trigger
    record = cluster_providers_gcp.create!(
      num_nodes: 1,
      gcp_project_id: 'test-project',
      zone: 'us-central1-a',
      cluster_id: cluster_belonging_to_organization.id,
      organization_id: nil,
      group_id: nil,
      project_id: nil
    )
    add_constraint_and_trigger
    record
  end

  let(:provider_with_partial_sharding_key) do
    cluster_providers_gcp.create!(
      num_nodes: 1,
      gcp_project_id: 'test-project',
      zone: 'us-central1-a',
      cluster_id: cluster_belonging_to_organization.id,
      organization_id: organization.id,
      group_id: nil,
      project_id: nil
    )
  end

  let(:provider_with_complete_sharding_key) do
    drop_constraint_and_trigger
    record = cluster_providers_gcp.create!(
      num_nodes: 1,
      gcp_project_id: 'test-project',
      zone: 'us-central1-a',
      cluster_id: cluster_belonging_to_organization.id,
      organization_id: organization.id,
      group_id: group.id,
      project_id: project.id
    )
    add_constraint_and_trigger
    record
  end

  subject(:migration) do
    described_class.new(
      start_id: cluster_providers_gcp.minimum(:id),
      end_id: cluster_providers_gcp.maximum(:id),
      batch_table: :cluster_providers_gcp,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe "#perform" do
    it 'backfills sharding key for records that do not have it' do
      provider_without_sharding_key.reload
      expect(provider_without_sharding_key.organization_id).to be_nil
      expect(provider_without_sharding_key.group_id).to be_nil
      expect(provider_without_sharding_key.project_id).to be_nil

      migration.perform

      provider_without_sharding_key.reload
      expect(provider_without_sharding_key.organization_id).to eq(organization.id)
      expect(provider_without_sharding_key.group_id).to be_nil
      expect(provider_without_sharding_key.project_id).to be_nil
    end

    it 'sets single sharding key' do
      provider_with_complete_sharding_key.reload
      expect(provider_with_complete_sharding_key.organization_id).to eq(organization.id)
      expect(provider_with_complete_sharding_key.group_id).to eq(group.id)
      expect(provider_with_complete_sharding_key.project_id).to eq(project.id)

      migration.perform

      provider_with_complete_sharding_key.reload
      expect(provider_with_complete_sharding_key.organization_id).to eq(organization.id)
      expect(provider_with_complete_sharding_key.group_id).to be_nil
      expect(provider_with_complete_sharding_key.project_id).to be_nil
    end

    it 'backfills sharding key for records with partial sharding key' do
      provider_with_partial_sharding_key.reload
      expect(provider_with_partial_sharding_key.organization_id).to eq(organization.id)
      expect(provider_with_partial_sharding_key.group_id).to be_nil
      expect(provider_with_partial_sharding_key.project_id).to be_nil

      migration.perform

      provider_with_partial_sharding_key.reload
      expect(provider_with_partial_sharding_key.organization_id).to eq(organization.id)
      expect(provider_with_partial_sharding_key.group_id).to be_nil
      expect(provider_with_partial_sharding_key.project_id).to be_nil
    end
  end

  private

  def drop_constraint_and_trigger
    connection.execute(
      <<~SQL
        DROP TRIGGER IF EXISTS #{trigger_name} ON cluster_providers_gcp;

        ALTER TABLE cluster_providers_gcp DROP CONSTRAINT IF EXISTS #{constraint_name};
      SQL
    )
  end

  def add_constraint_and_trigger
    connection.execute(
      <<~SQL
        ALTER TABLE cluster_providers_gcp ADD CONSTRAINT #{constraint_name} CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1)) NOT VALID;

        CREATE TRIGGER #{trigger_name} BEFORE INSERT OR UPDATE ON cluster_providers_gcp FOR EACH ROW EXECUTE FUNCTION #{function_name}();
      SQL
    )
  end
end
