# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddTypeToHttpIntegrations, feature_category: :incident_management do
  let(:integrations) { table(:alert_management_http_integrations) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(integrations.column_names).not_to include('type_identifier')
      }

      migration.after -> {
        integrations.reset_column_information
        expect(integrations.column_names).to include('type_identifier')
      }
    end
  end
end
