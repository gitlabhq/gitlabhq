# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddShardingKeyTriggerOnClusterProvidersGcp, feature_category: :deployment_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:clusters) { table(:clusters) }
  let(:cluster_providers_gcp) { table(:cluster_providers_gcp) }

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
    clusters.create!(name: 'cluster_with_group_id', cluster_type: 1, project_id: project.id)
  end

  describe '#up' do
    before do
      migrate!
    end

    context 'when inserting new records' do
      it 'sets sharding key columns from the parent clusters table' do
        provider1 = cluster_providers_gcp.create!(cluster_id: cluster_with_organization_id.id,
          gcp_project_id: 'project1', organization_id: nil, group_id: nil, project_id: nil,
          num_nodes: 0, status: 0, zone: 'zone1')
        provider2 = cluster_providers_gcp.create!(cluster_id: cluster_with_group_id.id, gcp_project_id: 'project2',
          organization_id: nil, group_id: nil, project_id: nil, num_nodes: 0, status: 0, zone: 'zone2')
        provider3 = cluster_providers_gcp.create!(cluster_id: cluster_with_project_id.id, gcp_project_id: 'project3',
          organization_id: nil, group_id: nil, project_id: nil, num_nodes: 0, status: 0, zone: 'zone3')

        provider1.reload
        expect(provider1.organization_id).to eq(organization.id)
        expect(provider1.group_id).to be_nil
        expect(provider1.project_id).to be_nil

        provider2.reload
        expect(provider2.organization_id).to be_nil
        expect(provider2.group_id).to eq(group.id)
        expect(provider2.project_id).to be_nil

        provider3.reload
        expect(provider3.organization_id).to be_nil
        expect(provider3.group_id).to be_nil
        expect(provider3.project_id).to eq(project.id)
      end
    end

    context 'when updating existing records' do
      it 'sets sharding key columns when updating a record without them' do
        ActiveRecord::Base.connection.execute(
          <<~SQL
            DROP TRIGGER IF EXISTS trigger_cluster_providers_gcp_sharding_key ON cluster_providers_gcp;

            ALTER TABLE cluster_providers_gcp DROP CONSTRAINT IF EXISTS check_fca4a4cb61;
          SQL
        )

        provider1 = cluster_providers_gcp.create!(cluster_id: cluster_with_organization_id.id,
          gcp_project_id: 'project1', organization_id: nil, group_id: nil, project_id: nil,
          num_nodes: 0, status: 0, zone: 'zone1')
        provider1.reload
        expect(provider1.organization_id).to be_nil
        expect(provider1.group_id).to be_nil
        expect(provider1.project_id).to be_nil

        provider2 = cluster_providers_gcp.create!(cluster_id: cluster_with_group_id.id,
          gcp_project_id: 'project2', organization_id: nil, group_id: nil, project_id: nil,
          num_nodes: 0, status: 0, zone: 'zone2')
        provider2.reload
        expect(provider2.organization_id).to be_nil
        expect(provider2.group_id).to be_nil
        expect(provider2.project_id).to be_nil

        provider3 = cluster_providers_gcp.create!(cluster_id: cluster_with_project_id.id,
          gcp_project_id: 'project3', organization_id: nil, group_id: nil, project_id: nil,
          num_nodes: 0, status: 0, zone: 'zone3')
        provider3.reload
        expect(provider3.organization_id).to be_nil
        expect(provider3.group_id).to be_nil
        expect(provider3.project_id).to be_nil

        ActiveRecord::Base.connection.execute(
          <<~SQL
            ALTER TABLE cluster_providers_gcp ADD CONSTRAINT check_fca4a4cb61 CHECK (num_nonnulls(group_id, organization_id, project_id) = 1) NOT VALID;

            CREATE TRIGGER trigger_cluster_providers_gcp_sharding_key BEFORE INSERT OR UPDATE ON cluster_providers_gcp FOR EACH ROW EXECUTE FUNCTION cluster_providers_gcp_sharding_key();
          SQL
        )

        # Update the record to trigger the function
        provider1.update!(gcp_project_id: 'project1_updated')
        provider1.reload

        expect(provider1.organization_id).to eq(organization.id)
        expect(provider1.group_id).to be_nil
        expect(provider1.project_id).to be_nil

        # Update the record to trigger the function
        provider2.update!(gcp_project_id: 'project2_updated')
        provider2.reload

        expect(provider2.organization_id).to be_nil
        expect(provider2.group_id).to eq(group.id)
        expect(provider2.project_id).to be_nil

        # Update the record to trigger the function
        provider3.update!(gcp_project_id: 'project3_updated')
        provider3.reload

        expect(provider3.organization_id).to be_nil
        expect(provider3.group_id).to be_nil
        expect(provider3.project_id).to eq(project.id)
      end
    end
  end
end
