# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddMcpServerSettingsToApplicationSettings, migration: :gitlab_main, feature_category: :mcp_server do
  describe '#up' do
    it 'adds mcp_server_settings jsonb column with NOT NULL DEFAULT {}' do
      migrate!

      col = ActiveRecord::Base.connection.columns(:application_settings).find { |c| c.name == 'mcp_server_settings' }
      expect(col).not_to be_nil
      expect(col.sql_type).to eq('jsonb')
      expect(col.default).to eq('{}')
      expect(col.null).to be false
    end
  end

  describe '#down' do
    it 'removes mcp_server_settings column' do
      migrate!
      schema_migrate_down!

      col = ActiveRecord::Base.connection.columns(:application_settings).find { |c| c.name == 'mcp_server_settings' }
      expect(col).to be_nil
    end
  end
end
