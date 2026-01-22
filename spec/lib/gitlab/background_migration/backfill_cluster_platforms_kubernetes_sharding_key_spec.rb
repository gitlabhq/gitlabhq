# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillClusterPlatformsKubernetesShardingKey, feature_category: :deployment_management do
  let(:connection) { ApplicationRecord.connection }

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:clusters) { table(:clusters) }
  let(:cluster_platforms_kubernetes) { table(:cluster_platforms_kubernetes) }

  let(:function_name) { 'cluster_platforms_kubernetes_sharding_key' }
  let(:trigger_name) { "trigger_#{function_name}" }
  let(:constraint_name) { 'check_73ecf3bb91' }

  let(:organization) { organizations.create!(name: 'name', path: 'path') }
  let(:namespace) { namespaces.create!(name: 'name', path: 'path', organization_id: organization.id) }
  let(:group) do
    namespaces.create!(name: 'test-group', path: 'test-group', type: 'Group', organization_id: organization.id)
  end

  let(:project) do
    projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, organization_id: organization.id)
  end

  let(:cluster_1) do
    clusters.create!(
      name: 'test-cluster 1',
      cluster_type: 1,
      organization_id: organization.id,
      group_id: nil,
      project_id: nil
    )
  end

  let(:cluster_2) do
    clusters.create!(
      name: 'test-cluster 2',
      cluster_type: 1,
      organization_id: organization.id,
      group_id: nil,
      project_id: nil
    )
  end

  let(:cluster_3) do
    clusters.create!(
      name: 'test-cluster 3',
      cluster_type: 1,
      organization_id: organization.id,
      group_id: nil,
      project_id: nil
    )
  end

  let!(:platform_with_null_sharding_key_columns) do
    drop_constraint_and_trigger
    record = cluster_platforms_kubernetes.create!(
      cluster_id: cluster_1.id,
      organization_id: nil,
      group_id: nil,
      project_id: nil
    )
    add_constraint_and_trigger
    record
  end

  let!(:platform_with_valid_sharding_key) do
    cluster_platforms_kubernetes.create!(
      cluster_id: cluster_2.id,
      organization_id: organization.id,
      group_id: nil,
      project_id: nil
    )
  end

  let!(:platform_with_multiple_sharding_key_columns_set) do
    drop_constraint_and_trigger
    record = cluster_platforms_kubernetes.create!(
      cluster_id: cluster_3.id,
      organization_id: organization.id,
      group_id: group.id,
      project_id: project.id
    )
    add_constraint_and_trigger
    record
  end

  subject(:migration) do
    described_class.new(
      start_id: cluster_platforms_kubernetes.minimum(:id),
      end_id: cluster_platforms_kubernetes.maximum(:id),
      batch_table: :cluster_platforms_kubernetes,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe "#perform" do
    it 'backfills sharding key for records that have all sharding key columns unset' do
      platform_with_null_sharding_key_columns.reload

      expect(platform_with_null_sharding_key_columns.group_id).to be_nil
      expect(platform_with_null_sharding_key_columns.project_id).to be_nil

      expect { migration.perform }.to change { platform_with_null_sharding_key_columns.reload.organization_id }
        .from(nil).to(organization.id)
        .and not_change { platform_with_null_sharding_key_columns.reload.group_id }
        .and not_change { platform_with_null_sharding_key_columns.reload.project_id }
    end

    it 'backfills sharding key for records that have multiple sharding key columns set' do
      platform_with_multiple_sharding_key_columns_set.reload

      expect(platform_with_multiple_sharding_key_columns_set.organization_id).to eq(organization.id)

      expect { migration.perform }.to not_change {
        platform_with_multiple_sharding_key_columns_set.reload.organization_id
      }
        .and change { platform_with_multiple_sharding_key_columns_set.reload.group_id }.from(group.id).to(nil)
        .and change { platform_with_multiple_sharding_key_columns_set.reload.project_id }.from(project.id).to(nil)
    end

    it 'does nothing for records that have a valid sharding key' do
      platform_with_valid_sharding_key.reload

      expect(platform_with_valid_sharding_key.organization_id).to eq(organization.id)
      expect(platform_with_valid_sharding_key.group_id).to be_nil
      expect(platform_with_valid_sharding_key.project_id).to be_nil

      expect { migration.perform }.to not_change { platform_with_valid_sharding_key.reload.organization_id }
        .and not_change { platform_with_valid_sharding_key.reload.group_id }
        .and not_change { platform_with_valid_sharding_key.reload.project_id }
    end
  end

  private

  def drop_constraint_and_trigger
    connection.execute(
      <<~SQL
        DROP TRIGGER IF EXISTS #{trigger_name} ON cluster_platforms_kubernetes;

        ALTER TABLE cluster_platforms_kubernetes DROP CONSTRAINT IF EXISTS #{constraint_name};
      SQL
    )
  end

  def add_constraint_and_trigger
    connection.execute(
      <<~SQL
        ALTER TABLE cluster_platforms_kubernetes ADD CONSTRAINT #{constraint_name} CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1)) NOT VALID;

        CREATE TRIGGER #{trigger_name} BEFORE INSERT OR UPDATE ON cluster_platforms_kubernetes FOR EACH ROW EXECUTE FUNCTION #{function_name}();
      SQL
    )
  end
end
