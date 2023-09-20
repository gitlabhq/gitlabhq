# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillAlertManagementPrometheusIntegrations, feature_category: :incident_management do
  let(:namespace_class) { table(:namespaces) }
  let(:project_class) { table(:projects) }
  let(:settings_class) { table(:project_alerting_settings) }
  let(:http_integrations_class) { table(:alert_management_http_integrations) }
  let(:integration_class) { table(:integrations) }

  let!(:namespace_1) { namespace_class.create!(name: "namespace_1", path: "namespace_1") }
  let!(:namespace_2) { namespace_class.create!(name: "namespace_2", path: "namespace_2") }
  let!(:namespace_3) { namespace_class.create!(name: "namespace_3", path: "namespace_3") }
  let!(:project_1) { project_class.create!(project_namespace_id: namespace_1.id, namespace_id: namespace_1.id) }
  let!(:project_2) { project_class.create!(project_namespace_id: namespace_2.id, namespace_id: namespace_1.id) }
  let!(:project_3) { project_class.create!(project_namespace_id: namespace_3.id, namespace_id: namespace_1.id) }

  let!(:http_integrations) do
    [
      create_http_integration(project_2, 'legacy', name: 'Legacy HTTP'),
      create_http_integration(project_2, 'other', name: 'Other Prometheus', type: 1)
    ]
  end

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)

    # disabled integration
    create_prometheus_integration(project_1, active: false)
    create_alerting_settings(project_1, token: :a)

    # enabled integration
    create_prometheus_integration(project_2, active: true)
    create_alerting_settings(project_2, token: :b)

    # settings without integration
    create_alerting_settings(project_3, token: :c)

    # Should ignore: another type of integration in the same project
    integration_class.create!(
      project_id: project_3.id,
      type_new: 'Integrations::Bamboo',
      active: true
    )
  end

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(http_integrations_class.all).to match_array(http_integrations)
      }

      migration.after -> {
        expect(http_integrations_class.all).to contain_exactly(
          *http_integrations,
          expected_http_integration(project_1, token: :a, active: false),
          expected_http_integration(project_2, token: :b, active: true),
          expected_http_integration(project_3, token: :c, active: false)
        )
      }
    end
  end

  context 'with existing synced http integrations' do
    let(:synced_integration) do
      create_http_integration(project_2, 'legacy-prometheus', name: 'Prometheus', active: false)
    end

    let!(:http_integrations) { [synced_integration] }

    it 'does not overwrite synced attributes' do
      expect { migrate! }.to not_change { synced_integration.attributes }

      expect(http_integrations_class.all).to contain_exactly(
        expected_http_integration(project_1, token: :a, active: false),
        synced_integration,
        expected_http_integration(project_3, token: :c, active: false)
      )
    end
  end

  private

  def create_prometheus_integration(project, active: true, **args)
    integration_class.create!(
      project_id: project.id,
      type_new: 'Integrations::Prometheus',
      active: active,
      **args
    )
  end

  def create_alerting_settings(project, token:)
    settings_class.create!(
      project_id: project.id,
      encrypted_token: "token_#{token}",
      encrypted_token_iv: "iv_#{token}"
    )
  end

  def create_http_integration(project, endpoint_id, type: 0, **args)
    http_integrations_class.create!(
      project_id: project.id,
      active: true,
      encrypted_token_iv: 'iv',
      encrypted_token: 'token',
      endpoint_identifier: endpoint_id,
      type_identifier: type,
      **args
    )
  end

  def expected_http_integration(project, token:, active:)
    having_attributes(
      project_id: project.id,
      active: active,
      encrypted_token: "token_#{token}",
      encrypted_token_iv: "iv_#{token}",
      name: 'Prometheus',
      endpoint_identifier: 'legacy-prometheus',
      type_identifier: 1
    )
  end
end
