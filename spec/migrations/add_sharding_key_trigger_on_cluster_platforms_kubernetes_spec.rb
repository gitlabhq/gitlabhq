# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddShardingKeyTriggerOnClusterPlatformsKubernetes, feature_category: :deployment_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:clusters) { table(:clusters) }
  let(:cluster_platforms_kubernetes) { table(:cluster_platforms_kubernetes) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }
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

  let(:cluster_belonging_to_group) do
    clusters.create!(
      name: 'test-cluster-2',
      cluster_type: 1,
      organization_id: nil,
      group_id: group.id,
      project_id: nil
    )
  end

  let(:cluster_belonging_to_project) do
    clusters.create!(
      name: 'test-cluster-3',
      cluster_type: 1,
      organization_id: nil,
      group_id: nil,
      project_id: project.id
    )
  end

  describe '#up' do
    before do
      migrate!
    end

    context 'when inserting new records' do
      it 'sets sharding key from the parent clusters table for organization' do
        platform = cluster_platforms_kubernetes.create!(
          cluster_id: cluster_belonging_to_organization.id,
          organization_id: nil,
          group_id: nil,
          project_id: nil
        )

        platform.reload
        expect(platform.organization_id).to eq(organization.id)
        expect(platform.group_id).to be_nil
        expect(platform.project_id).to be_nil
      end

      it 'sets sharding key from the parent clusters table for group' do
        platform = cluster_platforms_kubernetes.create!(
          cluster_id: cluster_belonging_to_group.id,
          organization_id: nil,
          group_id: nil,
          project_id: nil
        )

        platform.reload
        expect(platform.organization_id).to be_nil
        expect(platform.group_id).to eq(group.id)
        expect(platform.project_id).to be_nil
      end

      it 'sets sharding key from the parent clusters table for project' do
        platform = cluster_platforms_kubernetes.create!(
          cluster_id: cluster_belonging_to_project.id,
          organization_id: nil,
          group_id: nil,
          project_id: nil
        )

        platform.reload
        expect(platform.organization_id).to be_nil
        expect(platform.group_id).to be_nil
        expect(platform.project_id).to eq(project.id)
      end
    end

    context 'when updating existing records' do
      it 'sets sharding key when updating a record without sharding key' do
        connection = ApplicationRecord.connection
        connection.execute(
          <<~SQL
            DROP TRIGGER IF EXISTS trigger_cluster_platforms_kubernetes_sharding_key ON cluster_platforms_kubernetes;

            ALTER TABLE cluster_platforms_kubernetes DROP CONSTRAINT IF EXISTS check_73ecf3bb91;
          SQL
        )

        platform = cluster_platforms_kubernetes.create!(
          cluster_id: cluster_belonging_to_organization.id,
          organization_id: nil,
          group_id: nil,
          project_id: nil
        )
        platform.reload
        expect(platform.organization_id).to be_nil

        connection.execute(
          <<~SQL
            ALTER TABLE cluster_platforms_kubernetes ADD CONSTRAINT check_73ecf3bb91 CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1)) NOT VALID;

            CREATE TRIGGER trigger_cluster_platforms_kubernetes_sharding_key BEFORE INSERT OR UPDATE ON cluster_platforms_kubernetes FOR EACH ROW EXECUTE FUNCTION cluster_platforms_kubernetes_sharding_key();
          SQL
        )

        # Update the record to trigger the function
        platform.update!(encrypted_token: 'updated')
        platform.reload

        expect(platform.organization_id).to eq(organization.id)
        expect(platform.group_id).to be_nil
        expect(platform.project_id).to be_nil
      end
    end
  end
end
