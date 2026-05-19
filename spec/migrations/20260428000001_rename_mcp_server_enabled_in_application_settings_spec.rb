# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RenameMcpServerEnabledInApplicationSettings, migration: :gitlab_main, feature_category: :mcp_server do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    context 'when mcp_server_settings has the old enabled key' do
      let!(:app_setting) do
        application_settings.create!(
          duo_features_enabled: false,
          instance_level_ai_beta_features_enabled: false,
          mcp_server_settings: { 'enabled' => false }
        )
      end

      it 'renames enabled to mcp_server_enabled' do
        migrate!

        expect(app_setting.reload.mcp_server_settings).to eq({ 'mcp_server_enabled' => false })
      end
    end

    context 'when mcp_server_settings is empty' do
      let!(:app_setting) do
        application_settings.create!(
          duo_features_enabled: false,
          instance_level_ai_beta_features_enabled: false,
          mcp_server_settings: {}
        )
      end

      it 'leaves mcp_server_settings unchanged' do
        migrate!

        expect(app_setting.reload.mcp_server_settings).to eq({})
      end
    end

    context 'when mcp_server_settings already has mcp_server_enabled key' do
      let!(:app_setting) do
        application_settings.create!(
          duo_features_enabled: true,
          instance_level_ai_beta_features_enabled: true,
          mcp_server_settings: { 'mcp_server_enabled' => true }
        )
      end

      it 'leaves mcp_server_settings unchanged' do
        migrate!

        expect(app_setting.reload.mcp_server_settings).to eq({ 'mcp_server_enabled' => true })
      end
    end
  end

  describe '#down' do
    let!(:app_setting) do
      application_settings.create!(
        duo_features_enabled: false,
        instance_level_ai_beta_features_enabled: false,
        mcp_server_settings: { 'mcp_server_enabled' => false }
      )
    end

    it 'renames mcp_server_enabled back to enabled' do
      migrate!
      schema_migrate_down!

      expect(app_setting.reload.mcp_server_settings).to eq({ 'enabled' => false })
    end
  end
end
