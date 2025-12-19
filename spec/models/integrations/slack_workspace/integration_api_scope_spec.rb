# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackWorkspace::IntegrationApiScope, feature_category: :integrations do
  describe '.update_scopes' do
    let_it_be_with_reload(:instance_integration) { create(:slack_integration, :instance, :all_features_supported) }
    let_it_be_with_reload(:group_integration) { create(:slack_integration, :group, :all_features_supported) }
    let_it_be_with_reload(:project_integration) { create(:slack_integration, :project, :all_features_supported) }
    let(:integrations) { SlackIntegration.all }
    let(:first_scope) { instance_integration.slack_api_scopes.order(:id).limit(1) }

    subject(:inserted_scopes) { described_class.update_scopes(integrations, first_scope) }

    it 'updates all integrations with the specified scope and sets correct sharding keys', :aggregate_failures do
      expect do
        inserted_scopes
        # all_features_supported adds 3 scopes per integration. And we are removing 2 per integration.
      end.to change { Integrations::SlackWorkspace::IntegrationApiScope.count }.by(-6)

      expect(instance_integration.slack_integrations_scopes).to contain_exactly(
        have_attributes(
          slack_api_scope_id: first_scope.pick(:id),
          organization_id: instance_integration.organization.id,
          group_id: nil,
          project_id: nil
        )
      )
      expect(group_integration.slack_integrations_scopes).to contain_exactly(
        have_attributes(
          slack_api_scope_id: first_scope.pick(:id),
          organization_id: nil,
          group_id: group_integration.group.id,
          project_id: nil
        )
      )
      expect(project_integration.slack_integrations_scopes).to contain_exactly(
        have_attributes(
          slack_api_scope_id: first_scope.pick(:id),
          organization_id: nil,
          group_id: nil,
          project_id: project_integration.project.id
        )
      )
    end

    context 'when integrations is empty' do
      let(:integrations) { SlackIntegration.none }

      it 'returns early so it does not delete existing integrations' do
        expect do
          inserted_scopes
        end.not_to make_queries_matching(/DELETE FROM "slack_integrations_scopes"/)
      end
    end

    it 'prevents race conditions when inserting' do
      expect do
        inserted_scopes
      end.to make_queries_matching(/ON CONFLICT\s+DO NOTHING/)
    end

    context 'when slack_integrations belong to multiple organizations' do
      let_it_be(:organization2) { create(:organization) }
      let_it_be(:group2) { create(:group, organization: organization2) }
      let_it_be_with_reload(:group_integration2) do
        create(:slack_integration, :group, :all_features_supported, group: group2)
      end

      before do
        described_class.connection.execute(<<~SQL)
          ALTER TABLE slack_api_scopes DROP CONSTRAINT check_930d89be0d;
        SQL

        Integrations::SlackWorkspace::ApiScope.update_all(organization_id: nil)

        described_class.connection.execute(<<~SQL)
          ALTER TABLE slack_api_scopes
            ADD CONSTRAINT check_930d89be0d CHECK ((organization_id IS NOT NULL)) NOT VALID;
        SQL
      end

      it 'updates api scopes to new records that do have an organization_id', :aggregate_failures do
        expect do
          inserted_scopes
        end.to change { Integrations::SlackWorkspace::IntegrationApiScope.count }.by(-8).and(
          change { Integrations::SlackWorkspace::ApiScope.count }.by(2)
        )

        expect(organization2.id).not_to eq(instance_integration.organization_id)

        new_scope_org1 = Integrations::SlackWorkspace::ApiScope.find_by(
          name: first_scope.pick(:name), organization_id: instance_integration.organization.id
        )
        new_scope_org2 = Integrations::SlackWorkspace::ApiScope.find_by(
          name: first_scope.pick(:name), organization_id: organization2.id
        )

        expect(instance_integration.slack_integrations_scopes).to contain_exactly(
          have_attributes(
            slack_api_scope_id: new_scope_org1.id,
            organization_id: instance_integration.organization.id,
            group_id: nil,
            project_id: nil
          )
        )
        expect(group_integration.slack_integrations_scopes).to contain_exactly(
          have_attributes(
            slack_api_scope_id: new_scope_org1.id,
            organization_id: nil,
            group_id: group_integration.group.id,
            project_id: nil
          )
        )
        expect(project_integration.slack_integrations_scopes).to contain_exactly(
          have_attributes(
            slack_api_scope_id: new_scope_org1.id,
            organization_id: nil,
            group_id: nil,
            project_id: project_integration.project.id
          )
        )
        expect(group_integration2.slack_integrations_scopes).to contain_exactly(
          have_attributes(
            slack_api_scope_id: new_scope_org2.id,
            organization_id: nil,
            group_id: group2.id,
            project_id: nil
          )
        )
      end
    end
  end
end
