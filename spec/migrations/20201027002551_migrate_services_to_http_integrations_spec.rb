# frozen_string_literal: true

require 'spec_helper'
require_migration!('migrate_services_to_http_integrations')

RSpec.describe MigrateServicesToHttpIntegrations do
  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:project) { table(:projects).create!(id: 1, namespace_id: namespace.id) }
  let!(:alert_service) { table(:services).create!(type: 'AlertsService', project_id: project.id, active: true) }
  let!(:alert_service_data) { table(:alerts_service_data).create!(service_id: alert_service.id, encrypted_token: 'test', encrypted_token_iv: 'test')}
  let(:http_integrations) { table(:alert_management_http_integrations) }

  describe '#up' do
    it 'creates the http integrations from the alert services', :aggregate_failures do
      expect { migrate! }.to change { http_integrations.count }.by(1)

      http_integration = http_integrations.last
      expect(http_integration.project_id).to eq(alert_service.project_id)
      expect(http_integration.encrypted_token).to eq(alert_service_data.encrypted_token)
      expect(http_integration.encrypted_token_iv).to eq(alert_service_data.encrypted_token_iv)
      expect(http_integration.active).to eq(alert_service.active)
      expect(http_integration.name).to eq(described_class::SERVICE_NAMES_IDENTIFIER[:name])
      expect(http_integration.endpoint_identifier).to eq(described_class::SERVICE_NAMES_IDENTIFIER[:identifier])
    end
  end
end
