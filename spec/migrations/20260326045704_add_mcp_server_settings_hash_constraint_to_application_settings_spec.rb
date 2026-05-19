# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddMcpServerSettingsHashConstraintToApplicationSettings,
  migration: :gitlab_main,
  feature_category: :mcp_server do
  describe '#up' do
    it 'adds a check constraint ensuring mcp_server_settings is a JSON object' do
      migrate!

      constraint = ActiveRecord::Base.connection
        .check_constraints(:application_settings)
        .find { |c| c.name == 'check_application_settings_mcp_server_settings_is_hash' }

      expect(constraint).not_to be_nil
      expect(constraint.expression).to include('mcp_server_settings')
    end
  end

  describe '#down' do
    it 'removes the check constraint' do
      migrate!
      schema_migrate_down!

      constraint = ActiveRecord::Base.connection
        .check_constraints(:application_settings)
        .find { |c| c.name == 'check_application_settings_mcp_server_settings_is_hash' }

      expect(constraint).to be_nil
    end
  end
end
