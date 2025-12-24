# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- Necessary for BBM setup
RSpec.describe Gitlab::BackgroundMigration::BackfillSlackIntegrationsScopesShardingKey,
  :migration_with_transaction,
  feature_category: :integrations do
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }
  let(:integrations) { table(:integrations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:slack_integrations) { table(:slack_integrations) }
  let(:slack_integrations_scopes) { table(:slack_integrations_scopes) }
  let(:slack_api_scopes) { table(:slack_api_scopes) }
  let(:slack_integrations_scopes_archived) { table(:slack_integrations_scopes_archived) }

  let(:start_id) { slack_integrations_scopes.minimum(:id) }
  let(:end_id) { slack_integrations_scopes.maximum(:id) }

  let!(:organization) { organizations.create!(id: 1, name: 'Default', path: 'default') }
  let!(:other_organization) { organizations.create!(id: 2, name: 'Other', path: 'other') }
  let!(:group) { namespaces.create!(name: 'bar', path: 'bar', type: 'Group', organization_id: 1) }
  let!(:other_group) { namespaces.create!(name: 'bar2', path: 'bar2', type: 'Group', organization_id: 2) }
  let!(:user) { users.create!(organization_id: 1, email: 'user@example.com', username: 'user', projects_limit: 10) }

  let(:api_scope1) { slack_api_scopes.create!(name: 'scope1') }
  let(:api_scope2) { slack_api_scopes.create!(name: 'scope2') }
  let(:api_scope3) { slack_api_scopes.create!(name: 'scope3', organization_id: other_organization.id) }
  let(:duplicate_scope3) { slack_api_scopes.create!(name: 'scope3') }

  let!(:project) do
    projects.create!(
      name: 'baz',
      path: 'baz',
      organization_id: 1,
      namespace_id: group.id,
      project_namespace_id: group.id
    )
  end

  let!(:another_project_namespace) do
    namespaces.create!(name: 'another_namespace', path: 'another_namespace', organization_id: 1)
  end

  let!(:another_project) do
    projects.create!(
      name: 'another',
      path: 'another',
      organization_id: 1,
      namespace_id: another_project_namespace.id,
      project_namespace_id: another_project_namespace.id
    )
  end

  let!(:organization_integration) do
    integrations.create!(
      instance: true,
      organization_id: organization.id,
      type_new: 'Integrations::GitlabSlackApplication'
    )
  end

  let!(:org_slack_integration) do
    slack_integrations.create!(
      user_id: user.id,
      integration_id: organization_integration.id,
      team_id: 'ORG123',
      team_name: 'GitLab Organization',
      alias: '_gitlab-instance'
    )
  end

  let(:org_slack_integration_scope1) do
    slack_integrations_scopes.create!(
      slack_api_scope_id: api_scope1.id,
      slack_integration_id: org_slack_integration.id
    )
  end

  let(:org_slack_integration_scope2) do
    slack_integrations_scopes.create!(
      slack_api_scope_id: api_scope2.id,
      slack_integration_id: org_slack_integration.id
    )
  end

  let!(:other_organization_integration) do
    integrations.create!(
      instance: true,
      organization_id: other_organization.id,
      type_new: 'Integrations::GitlabSlackApplication'
    )
  end

  let!(:other_org_slack_integration) do
    slack_integrations.create!(
      user_id: user.id,
      integration_id: other_organization_integration.id,
      team_id: 'ORG1234',
      team_name: 'GitLab Other Organization',
      alias: '_gitlab-instance-o'
    )
  end

  let(:other_org_slack_integration_scope1) do
    slack_integrations_scopes.create!(
      slack_api_scope_id: api_scope3.id,
      slack_integration_id: other_org_slack_integration.id
    )
  end

  let(:other_org_slack_integration_scope2) do
    slack_integrations_scopes.create!(
      slack_api_scope_id: duplicate_scope3.id,
      slack_integration_id: other_org_slack_integration.id
    )
  end

  let!(:group_integration) do
    integrations.create!(
      group_id: group.id,
      type_new: 'Integrations::GitlabSlackApplication'
    )
  end

  let!(:group_slack_integration) do
    slack_integrations.create!(
      user_id: user.id,
      integration_id: group_integration.id,
      team_id: 'GRP123',
      team_name: 'GitLab Group',
      alias: group.path
    )
  end

  let(:group_slack_integration_scope1) do
    slack_integrations_scopes.create!(
      slack_api_scope_id: api_scope1.id,
      slack_integration_id: group_slack_integration.id
    )
  end

  let(:group_slack_integration_scope2) do
    slack_integrations_scopes.create!(
      slack_api_scope_id: api_scope2.id,
      slack_integration_id: group_slack_integration.id
    )
  end

  let!(:other_group_integration) do
    integrations.create!(
      group_id: other_group.id,
      type_new: 'Integrations::GitlabSlackApplication'
    )
  end

  let!(:other_group_slack_integration) do
    slack_integrations.create!(
      user_id: user.id,
      integration_id: other_group_integration.id,
      team_id: 'GRP1234',
      team_name: 'GitLab Group 2',
      alias: other_group.path
    )
  end

  let(:other_group_slack_integration_scope1) do
    slack_integrations_scopes.create!(
      slack_api_scope_id: api_scope1.id,
      slack_integration_id: other_group_slack_integration.id
    )
  end

  let(:other_group_slack_integration_scope2) do
    slack_integrations_scopes.create!(
      slack_api_scope_id: api_scope2.id,
      slack_integration_id: other_group_slack_integration.id
    )
  end

  let!(:project_integration) do
    integrations.create!(
      project_id: project.id,
      type_new: 'Integrations::GitlabSlackApplication'
    )
  end

  let!(:project_slack_integration) do
    slack_integrations.create!(
      user_id: user.id,
      integration_id: project_integration.id,
      team_id: 'ABC123',
      team_name: 'GitLab Project',
      alias: project.path
    )
  end

  let(:project_slack_integration_scope1) do
    slack_integrations_scopes.create!(
      slack_api_scope_id: api_scope1.id,
      slack_integration_id: project_slack_integration.id,
      project_id: project.id
    )
  end

  let(:project_slack_integration_scope2) do
    slack_integrations_scopes.create!(
      slack_api_scope_id: api_scope2.id,
      slack_integration_id: project_slack_integration.id
    )
  end

  let!(:another_project_integration) do
    integrations.create!(
      project_id: another_project.id,
      type_new: 'Integrations::GitlabSlackApplication'
    )
  end

  let!(:another_project_slack_integration) do
    slack_integrations.create!(
      user_id: user.id,
      integration_id: another_project_integration.id,
      project_id: another_project.id,
      team_id: 'PRJ1234',
      team_name: 'GitLab Project2',
      alias: another_project.path
    )
  end

  let(:another_project_slack_integration_scope1) do
    slack_integrations_scopes.create!(
      slack_api_scope_id: api_scope1.id,
      slack_integration_id: another_project_slack_integration.id
    )
  end

  let(:another_project_slack_integration_scope2) do
    slack_integrations_scopes.create!(
      slack_api_scope_id: api_scope2.id,
      slack_integration_id: another_project_slack_integration.id
    )
  end

  subject(:migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :slack_integrations_scopes,
      batch_column: :id,
      sub_batch_size: 5,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe "#perform" do
    before do
      slack_integrations_scopes.connection.execute(<<~SQL)
        ALTER TABLE slack_integrations_scopes DROP CONSTRAINT check_c5ff08a699;
        ALTER TABLE slack_api_scopes DROP CONSTRAINT check_930d89be0d;
      SQL

      org_slack_integration_scope1
      org_slack_integration_scope2
      other_org_slack_integration_scope1
      other_org_slack_integration_scope2
      group_slack_integration_scope1
      group_slack_integration_scope2
      other_group_slack_integration_scope1
      other_group_slack_integration_scope2
      project_slack_integration_scope1
      project_slack_integration_scope2
      another_project_slack_integration_scope1
      another_project_slack_integration_scope2

      slack_integrations_scopes.connection.execute(<<~SQL)
        ALTER TABLE slack_integrations_scopes
          ADD CONSTRAINT check_c5ff08a699 CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1)) NOT VALID;
        ALTER TABLE slack_api_scopes
          ADD CONSTRAINT check_930d89be0d CHECK ((organization_id IS NOT NULL)) NOT VALID;
      SQL
    end

    it 'sets slack_integrations_scopes sharding key. Upserts slack_api_scopes', :aggregate_failures do
      expect(org_slack_integration_scope1.project_id).to be_nil
      expect(org_slack_integration_scope1.group_id).to be_nil
      expect(org_slack_integration_scope1.organization_id).to be_nil
      expect(org_slack_integration_scope1.slack_api_scope_id).to eq(api_scope1.id)
      expect(org_slack_integration_scope2.project_id).to be_nil
      expect(org_slack_integration_scope2.group_id).to be_nil
      expect(org_slack_integration_scope2.organization_id).to be_nil
      expect(org_slack_integration_scope2.slack_api_scope_id).to eq(api_scope2.id)

      expect(other_org_slack_integration_scope1.project_id).to be_nil
      expect(other_org_slack_integration_scope1.group_id).to be_nil
      expect(other_org_slack_integration_scope1.organization_id).to be_nil
      expect(other_org_slack_integration_scope1.slack_api_scope_id).to eq(api_scope3.id)
      expect(other_org_slack_integration_scope2.project_id).to be_nil
      expect(other_org_slack_integration_scope2.group_id).to be_nil
      expect(other_org_slack_integration_scope2.organization_id).to be_nil
      expect(other_org_slack_integration_scope2.slack_api_scope_id).to eq(duplicate_scope3.id)

      expect(group_slack_integration_scope1.project_id).to be_nil
      expect(group_slack_integration_scope1.group_id).to be_nil
      expect(group_slack_integration_scope1.organization_id).to be_nil
      expect(group_slack_integration_scope1.slack_api_scope_id).to eq(api_scope1.id)
      expect(group_slack_integration_scope2.project_id).to be_nil
      expect(group_slack_integration_scope2.group_id).to be_nil
      expect(group_slack_integration_scope2.organization_id).to be_nil
      expect(group_slack_integration_scope2.slack_api_scope_id).to eq(api_scope2.id)

      expect(project_slack_integration_scope1.project_id).to eq(project.id)
      expect(project_slack_integration_scope1.group_id).to be_nil
      expect(project_slack_integration_scope1.organization_id).to be_nil
      expect(project_slack_integration_scope1.slack_api_scope_id).to eq(api_scope1.id)
      expect(project_slack_integration_scope2.project_id).to be_nil
      expect(project_slack_integration_scope2.group_id).to be_nil
      expect(project_slack_integration_scope2.organization_id).to be_nil
      expect(project_slack_integration_scope2.slack_api_scope_id).to eq(api_scope2.id)

      expect(another_project_slack_integration_scope1.project_id).to be_nil
      expect(another_project_slack_integration_scope1.group_id).to be_nil
      expect(another_project_slack_integration_scope1.organization_id).to be_nil
      expect(another_project_slack_integration_scope1.slack_api_scope_id).to eq(api_scope1.id)
      expect(another_project_slack_integration_scope2.project_id).to be_nil
      expect(another_project_slack_integration_scope2.group_id).to be_nil
      expect(another_project_slack_integration_scope2.organization_id).to be_nil
      expect(another_project_slack_integration_scope2.slack_api_scope_id).to eq(api_scope2.id)

      expect(api_scope1.organization_id).to be_nil
      expect(api_scope2.organization_id).to be_nil
      expect(api_scope3.organization_id).to eq(other_organization.id)

      expect do
        migration.perform
      end.to change { slack_api_scopes.count }.from(4).to(8).and(
        not_change { api_scope3.reload.organization_id }.from(other_organization.id)
      ).and(
        # The final count on this table is only -1 as we only had 1 duplicate record with the same scope name
        change { slack_integrations_scopes.count }.by(-1)
      ).and(
        # 11 records are inserted and deleted in the original table
        change { slack_integrations_scopes_archived.count }.by(11)
      )

      # These are the 4 new `slack_api_scopes` records that were created while upserting each batch
      new_scope1_org = slack_api_scopes.find_by(name: api_scope1.name, organization_id: organization.id)
      new_scope2_org = slack_api_scopes.find_by(name: api_scope2.name, organization_id: organization.id)
      new_scope1_other_org = slack_api_scopes.find_by(name: api_scope1.name, organization_id: other_organization.id)
      new_scope2_other_org = slack_api_scopes.find_by(name: api_scope2.name, organization_id: other_organization.id)

      # We need to find new records as we are upserting and not only updating
      new_org_slack_integration_scope1 = slack_integrations_scopes.find_by(
        slack_api_scope_id: new_scope1_org.id,
        slack_integration_id: org_slack_integration_scope1.slack_integration_id
      )
      new_org_slack_integration_scope2 = slack_integrations_scopes.find_by(
        slack_api_scope_id: new_scope2_org.id,
        slack_integration_id: org_slack_integration_scope2.slack_integration_id
      )
      new_other_org_slack_integration_scope2 = slack_integrations_scopes.find_by(
        slack_api_scope_id: api_scope3.id,
        slack_integration_id: other_org_slack_integration_scope2.slack_integration_id
      )
      new_group_slack_integration_scope1 = slack_integrations_scopes.find_by(
        slack_api_scope_id: new_scope1_org.id,
        slack_integration_id: group_slack_integration_scope1.slack_integration_id
      )
      new_group_slack_integration_scope2 = slack_integrations_scopes.find_by(
        slack_api_scope_id: new_scope2_org.id,
        slack_integration_id: group_slack_integration_scope2.slack_integration_id
      )
      new_other_group_slack_integration_scope1 = slack_integrations_scopes.find_by(
        slack_api_scope_id: new_scope1_other_org.id,
        slack_integration_id: other_group_slack_integration_scope1.slack_integration_id
      )
      new_other_group_slack_integration_scope2 = slack_integrations_scopes.find_by(
        slack_api_scope_id: new_scope2_other_org.id,
        slack_integration_id: other_group_slack_integration_scope2.slack_integration_id
      )
      new_project_slack_integration_scope1 = slack_integrations_scopes.find_by(
        slack_api_scope_id: new_scope1_org.id,
        slack_integration_id: project_slack_integration_scope1.slack_integration_id
      )
      new_project_slack_integration_scope2 = slack_integrations_scopes.find_by(
        slack_api_scope_id: new_scope2_org.id,
        slack_integration_id: project_slack_integration_scope2.slack_integration_id
      )
      new_another_project_slack_integration_scope1 = slack_integrations_scopes.find_by(
        slack_api_scope_id: new_scope1_org.id,
        slack_integration_id: another_project_slack_integration_scope1.slack_integration_id
      )
      new_another_project_slack_integration_scope2 = slack_integrations_scopes.find_by(
        slack_api_scope_id: new_scope2_org.id,
        slack_integration_id: another_project_slack_integration_scope2.slack_integration_id
      )

      expect(new_org_slack_integration_scope1.project_id).to be_nil
      expect(new_org_slack_integration_scope1.group_id).to be_nil
      expect(new_org_slack_integration_scope1.organization_id).to eq(organization.id)
      expect(new_org_slack_integration_scope1.slack_api_scope_id).to eq(new_scope1_org.id)
      expect(new_org_slack_integration_scope2.project_id).to be_nil
      expect(new_org_slack_integration_scope2.group_id).to be_nil
      expect(new_org_slack_integration_scope2.organization_id).to eq(organization.id)
      expect(new_org_slack_integration_scope2.slack_api_scope_id).to eq(new_scope2_org.id)

      # other_org_slack_integration_scope1 is the only record that is not recreated with the correct sharding key
      # as it was already associated with a valid api_scope record with a sharding key
      expect(other_org_slack_integration_scope1.reload.project_id).to be_nil
      expect(other_org_slack_integration_scope1.group_id).to be_nil
      expect(other_org_slack_integration_scope1.organization_id).to eq(other_organization.id)
      expect(other_org_slack_integration_scope1.slack_api_scope_id).to eq(api_scope3.id)
      expect(new_other_org_slack_integration_scope2.reload.project_id).to be_nil
      expect(new_other_org_slack_integration_scope2.group_id).to be_nil
      expect(new_other_org_slack_integration_scope2.organization_id).to eq(other_organization.id)
      expect(new_other_org_slack_integration_scope2.slack_api_scope_id).to eq(api_scope3.id)

      expect(new_group_slack_integration_scope1.project_id).to be_nil
      expect(new_group_slack_integration_scope1.group_id).to eq(group.id)
      expect(new_group_slack_integration_scope1.organization_id).to be_nil
      expect(new_group_slack_integration_scope1.slack_api_scope_id).to eq(new_scope1_org.id)
      expect(new_group_slack_integration_scope2.project_id).to be_nil
      expect(new_group_slack_integration_scope2.group_id).to eq(group.id)
      expect(new_group_slack_integration_scope2.organization_id).to be_nil
      expect(new_group_slack_integration_scope2.slack_api_scope_id).to eq(new_scope2_org.id)

      expect(new_other_group_slack_integration_scope1.project_id).to be_nil
      expect(new_other_group_slack_integration_scope1.group_id).to eq(other_group.id)
      expect(new_other_group_slack_integration_scope1.organization_id).to be_nil
      expect(new_other_group_slack_integration_scope1.slack_api_scope_id).to eq(new_scope1_other_org.id)
      expect(new_other_group_slack_integration_scope2.project_id).to be_nil
      expect(new_other_group_slack_integration_scope2.group_id).to eq(other_group.id)
      expect(new_other_group_slack_integration_scope2.organization_id).to be_nil
      expect(new_other_group_slack_integration_scope2.slack_api_scope_id).to eq(new_scope2_other_org.id)

      expect(new_project_slack_integration_scope1.project_id).to eq(project.id)
      expect(new_project_slack_integration_scope1.group_id).to be_nil
      expect(new_project_slack_integration_scope1.organization_id).to be_nil
      expect(new_project_slack_integration_scope1.slack_api_scope_id).to eq(new_scope1_org.id)
      expect(new_project_slack_integration_scope2.project_id).to eq(project.id)
      expect(new_project_slack_integration_scope2.group_id).to be_nil
      expect(new_project_slack_integration_scope2.organization_id).to be_nil
      expect(new_project_slack_integration_scope2.slack_api_scope_id).to eq(new_scope2_org.id)

      expect(new_another_project_slack_integration_scope1.project_id).to eq(another_project.id)
      expect(new_another_project_slack_integration_scope1.group_id).to be_nil
      expect(new_another_project_slack_integration_scope1.organization_id).to be_nil
      expect(new_another_project_slack_integration_scope1.slack_api_scope_id).to eq(new_scope1_org.id)
      expect(new_another_project_slack_integration_scope2.project_id).to eq(another_project.id)
      expect(new_another_project_slack_integration_scope2.group_id).to be_nil
      expect(new_another_project_slack_integration_scope2.organization_id).to be_nil
      expect(new_another_project_slack_integration_scope2.slack_api_scope_id).to eq(new_scope2_org.id)

      # These will be deleted after the backfill is finalized
      expect(api_scope1.reload.organization_id).to be_nil
      expect(api_scope2.reload.organization_id).to be_nil

      # This one stays as it already had an organization_id
      expect(api_scope3.reload.organization_id).to eq(other_organization.id)
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
