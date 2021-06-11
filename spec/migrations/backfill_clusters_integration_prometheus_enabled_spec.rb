# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillClustersIntegrationPrometheusEnabled, :migration do
  def create_cluster!(label = rand(2**64).to_s)
    table(:clusters).create!(
      name: "cluster: #{label}",
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )
  end

  def create_clusters_applications_prometheus!(label, status:, cluster_id: nil)
    table(:clusters_applications_prometheus).create!(
      cluster_id: cluster_id || create_cluster!(label).id,
      status: status,
      version: "#{label}: version",
      created_at: 1.day.ago, # artificially aged
      updated_at: 1.day.ago, # artificially aged
      encrypted_alert_manager_token: "#{label}: token",
      encrypted_alert_manager_token_iv: "#{label}: iv"
    )
  end

  def create_clusters_integration_prometheus!
    table(:clusters_integration_prometheus).create!(
      cluster_id: create_cluster!.id,
      enabled: false,
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )
  end

  RSpec::Matchers.define :be_enabled_and_match_application_values do |application|
    match do |actual|
      actual.enabled == true &&
        actual.encrypted_alert_manager_token == application.encrypted_alert_manager_token &&
        actual.encrypted_alert_manager_token_iv == application.encrypted_alert_manager_token_iv
    end
  end

  describe '#up' do
    it 'backfills the enabled status and alert manager credentials from clusters_applications_prometheus' do
      status_installed = 3
      status_externally_installed = 11
      status_installable = 0

      existing_integration = create_clusters_integration_prometheus!
      unaffected_existing_integration = create_clusters_integration_prometheus!
      app_installed = create_clusters_applications_prometheus!('installed', status: status_installed)
      app_installed_existing_integration = create_clusters_applications_prometheus!('installed, existing integration', status: status_installed, cluster_id: existing_integration.cluster_id)
      app_externally_installed = create_clusters_applications_prometheus!('externally installed', status: status_externally_installed)
      app_other_status = create_clusters_applications_prometheus!('other status', status: status_installable)

      migrate!

      integrations = table(:clusters_integration_prometheus).all.index_by(&:cluster_id)

      expect(unaffected_existing_integration.reload).to eq unaffected_existing_integration

      integration_installed = integrations[app_installed.cluster_id]
      expect(integration_installed).to be_enabled_and_match_application_values(app_installed)
      expect(integration_installed.updated_at).to be >= 1.minute.ago # recently updated
      expect(integration_installed.updated_at).to eq(integration_installed.created_at) # recently created

      expect(existing_integration.reload).to be_enabled_and_match_application_values(app_installed_existing_integration)
      expect(existing_integration.updated_at).to be >= 1.minute.ago # recently updated
      expect(existing_integration.updated_at).not_to eq(existing_integration.created_at) # but not recently created

      integration_externally_installed = integrations[app_externally_installed.cluster_id]
      expect(integration_externally_installed).to be_enabled_and_match_application_values(app_externally_installed)
      expect(integration_externally_installed.updated_at).to be >= 1.minute.ago # recently updated
      expect(integration_externally_installed.updated_at).to eq(integration_externally_installed.created_at) # recently created

      expect(integrations[app_other_status.cluster_id]).to be_nil
    end
  end
end
