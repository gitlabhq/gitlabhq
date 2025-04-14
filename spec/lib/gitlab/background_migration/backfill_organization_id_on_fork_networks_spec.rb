# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOrganizationIdOnForkNetworks, feature_category: :source_code_management do
  let(:fork_networks_table) { table(:fork_networks) }
  let(:fork_network_members_table) { table(:fork_network_members) }
  let(:namespaces_table) { table(:namespaces) }
  let(:organizations_table) { table(:organizations) }
  let(:projects_table) { table(:projects) }

  let!(:default_organization) { organizations_table.create!(name: "Organization", path: "organization") }
  let(:namespace) { namespaces_table.create!(name: 'Test', path: 'test', organization_id: default_organization.id) }

  let!(:another_organization) { organizations_table.create!(name: "Another", path: "another") }
  let(:another_namespace) do
    namespaces_table.create!(name: 'Test 2', path: 'test-2', organization_id: another_organization.id)
  end

  let(:project) do
    projects_table.create!(
      name: 'project',
      path: 'project',
      namespace_id: another_namespace.id,
      project_namespace_id: another_namespace.id,
      organization_id: another_organization.id
    )
  end

  let(:args) do
    min, max = fork_networks_table.pick('MIN(id)', 'MAX(id)')

    {
      start_id: min,
      end_id: max,
      batch_table: 'fork_networks',
      batch_column: 'id',
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  subject(:perform_migration) { described_class.new(**args).perform }

  context 'when root project exists' do
    let(:fork_network) { fork_networks_table.create!(root_project_id: project.id) }

    it 'updates the organization_id with the organization_id of the root project' do
      expect { perform_migration }.to change {
        fork_network.reload.organization_id
      }.from(nil).to(project.organization_id)
    end
  end

  context 'when root project is deleted' do
    let(:fork_network) { fork_networks_table.create!(root_project_id: nil) }

    context 'and a fork_network_member exists' do
      before do
        forked_namespace = namespaces_table.create!(name: 'Test 3', path: 'test-3',
          organization_id: another_organization.id)

        forked_project = projects_table.create!(
          name: 'forked project',
          path: 'forked-project',
          namespace_id: forked_namespace.id,
          project_namespace_id: forked_namespace.id,
          organization_id: another_organization.id
        )

        fork_network_members_table.create!(fork_network_id: fork_network.id,
          forked_from_project_id: project.id, project_id: forked_project.id)
      end

      it 'updates the organization_id via the fork_network_member' do
        expect { perform_migration }.to change {
          fork_network.reload.organization_id
        }.from(nil).to(project.organization_id)
      end
    end

    context 'and no fork_network_member exists' do
      context 'when organization with ID 1 exists' do
        let!(:org_id_1) { organizations_table.create!(id: 1, name: "Primary Org", path: "primary-org") }

        it 'uses organization with ID 1 as the default' do
          expect { perform_migration }.to change {
            fork_network.reload.organization_id
          }.from(nil).to(org_id_1.id)
        end
      end

      context 'when organization with ID 1 does not exist' do
        before do
          organizations_table.where(id: 1).delete_all
        end

        it 'falls back to the first organization' do
          expect(Organizations::Organization.first.id).to eq(default_organization.id)

          expect { perform_migration }.to change {
            fork_network.reload.organization_id
          }.from(nil).to(default_organization.id)
        end
      end
    end
  end
end
