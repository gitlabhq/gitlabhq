# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackWorkspace::IntegrationApiScope, feature_category: :integrations do
  describe '.update_scopes' do
    let_it_be(:instance_integration) { create(:slack_integration, :instance, :all_features_supported) }
    let_it_be(:group_integration) { create(:slack_integration, :group, :all_features_supported) }
    let_it_be(:project_integration) { create(:slack_integration, :project, :all_features_supported) }
    let(:integrations) { SlackIntegration.all }
    let(:first_scope) { instance_integration.slack_api_scopes.order(:id).limit(1) }

    subject(:inserted_scopes) { described_class.update_scopes(integrations, first_scope) }

    it 'updates all integrations with the specified scope and sets correct sharding keys', :aggregate_failures do
      expect do
        inserted_scopes
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
  end
end
