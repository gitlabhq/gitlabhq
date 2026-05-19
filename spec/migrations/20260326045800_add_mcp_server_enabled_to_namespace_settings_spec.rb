# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddMcpServerEnabledToNamespaceSettings, migration: :gitlab_main, feature_category: :mcp_server do
  describe '#up' do
    it 'adds nullable mcp_server_enabled column with no default' do
      migrate!

      col = ActiveRecord::Base.connection.columns(:namespace_settings).find { |c| c.name == 'mcp_server_enabled' }
      expect(col).not_to be_nil
      expect(col.null).to be true
      expect(col.default).to be_nil
    end
  end

  describe '#down' do
    it 'removes mcp_server_enabled column' do
      migrate!
      schema_migrate_down!

      col = ActiveRecord::Base.connection.columns(:namespace_settings).find { |c| c.name == 'mcp_server_enabled' }
      expect(col).to be_nil
    end
  end
end
