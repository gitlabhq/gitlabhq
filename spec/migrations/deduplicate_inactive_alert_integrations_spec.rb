# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeduplicateInactiveAlertIntegrations, feature_category: :incident_management do
  let!(:namespace_class) { table(:namespaces) }
  let!(:project_class) { table(:projects) }
  let!(:integration_class) { table(:alert_management_http_integrations) }

  let!(:namespace_0) { namespace_class.create!(name: 'namespace1', path: 'namespace1') }
  let!(:namespace_1) { namespace_class.create!(name: 'namespace2', path: 'namespace2') }
  let!(:namespace_2) { namespace_class.create!(name: 'namespace3', path: 'namespace3') }

  let!(:project_with_inactive_duplicate) { create_project(namespace_0, namespace_0) }
  let!(:project_with_multiple_duplicates) { create_project(namespace_0, namespace_1) }
  let!(:project_without_duplicates) { create_project(namespace_0, namespace_2) }

  let!(:integrations) do
    [
      create_integration(project_with_inactive_duplicate, 'default'),
      create_integration(project_with_inactive_duplicate, 'other'),
      create_integration(project_with_inactive_duplicate, 'other', active: false),
      create_integration(project_with_multiple_duplicates, 'default', active: false),
      create_integration(project_with_multiple_duplicates, 'default', active: false),
      create_integration(project_with_multiple_duplicates, 'other', active: false),
      create_integration(project_with_multiple_duplicates, 'other'),
      create_integration(project_without_duplicates, 'default'),
      create_integration(project_without_duplicates, 'other', active: false)
    ]
  end

  describe '#up' do
    it 'updates the endpoint identifier of duplicate inactive integrations' do
      expect { migrate! }
        .to not_change { integrations[0].reload }
        .and not_change { integrations[1].reload }
        .and not_change { integrations[6].reload }
        .and not_change { integrations[7].reload }
        .and not_change { integrations[8].reload }

      expect { integrations[2].reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { integrations[3].reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { integrations[4].reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { integrations[5].reload }.to raise_error(ActiveRecord::RecordNotFound)

      endpoints = integration_class.pluck(:endpoint_identifier, :project_id)
      expect(endpoints.uniq).to match_array(endpoints)
    end
  end

  private

  def create_integration(project, endpoint_identifier, active: true)
    integration_class.create!(
      project_id: project.id,
      endpoint_identifier: endpoint_identifier,
      active: active,
      encrypted_token_iv: 'iv',
      encrypted_token: 'token',
      name: "HTTP Integration - #{endpoint_identifier}"
    )
  end

  def create_project(namespace, project_namespace)
    project_class.create!(
      namespace_id: namespace.id,
      project_namespace_id: project_namespace.id
    )
  end
end
