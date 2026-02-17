# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteLegacySlackApiScopesRecords, :migration_with_transaction, migration: :gitlab_main_org, feature_category: :integrations do
  let(:slack_integrations) { table(:slack_integrations) }
  let(:integrations) { table(:integrations) }
  let(:slack_integrations_scopes) { table(:slack_integrations_scopes) }
  let(:slack_api_scopes) { table(:slack_api_scopes) }
  let(:users) { table(:users) }
  let(:organization) { table(:organizations).create!(id: 1, name: 'Default', path: 'default') }
  let(:legacy_api_scope) { slack_api_scopes.create!(name: 'legacy1', organization_id: nil) }
  let(:new_api_scope) { slack_api_scopes.create!(name: 'new1', organization_id: organization.id) }
  let(:user) do
    users.create!(organization_id: organization.id, email: 'user@example.com', username: 'user', projects_limit: 10)
  end

  let(:organization_integration) do
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
      alias: '_gitlab-instance',
      organization_id: organization.id
    )
  end

  before do
    slack_integrations_scopes.connection.execute(<<~SQL)
      ALTER TABLE slack_api_scopes DROP CONSTRAINT check_930d89be0d;
    SQL

    legacy_api_scope
    new_api_scope

    slack_integrations_scopes.create!(
      slack_api_scope_id: new_api_scope.id,
      slack_integration_id: org_slack_integration.id,
      organization_id: organization.id
    )

    slack_integrations_scopes.connection.execute(<<~SQL)
      ALTER TABLE slack_api_scopes
        ADD CONSTRAINT check_930d89be0d CHECK ((organization_id IS NOT NULL)) NOT VALID;
    SQL
  end

  context 'when invalid records still exist in slack_integrations_scopes' do
    before do
      slack_integrations_scopes.create!(
        slack_api_scope_id: legacy_api_scope.id,
        slack_integration_id: org_slack_integration.id,
        organization_id: organization.id
      )
    end

    it 'raises an error' do
      expect do
        migrate!
      end.to raise_error(StandardError, include(described_class::ERROR_MESSAGE))
    end
  end

  context 'when no invalid records exist' do
    it 'deletes legacy records' do
      expect do
        migrate!
      end.to not_change { slack_integrations_scopes.count }.from(1).and(
        change { slack_api_scopes.count }.by(-1)
      )

      expect(slack_api_scopes.find_by(id: new_api_scope.id)).to eq(new_api_scope)
    end
  end
end
