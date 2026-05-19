# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillMcpServerEnabledOnApplicationSettings, migration: :gitlab_main, feature_category: :mcp_server do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    context 'when duo_features_enabled and instance_level_ai_beta_features_enabled are both true' do
      let!(:app_setting) do
        application_settings.create!(
          duo_features_enabled: true,
          instance_level_ai_beta_features_enabled: true,
          mcp_server_settings: { 'enabled' => true }
        )
      end

      it 'leaves mcp_server_settings enabled as true' do
        migrate!

        expect(app_setting.reload.mcp_server_settings['enabled']).to be true
      end
    end

    context 'when duo_features_enabled is false' do
      let!(:app_setting) do
        application_settings.create!(
          duo_features_enabled: false,
          instance_level_ai_beta_features_enabled: true,
          mcp_server_settings: { 'enabled' => true }
        )
      end

      it 'sets mcp_server_settings enabled to false' do
        migrate!

        expect(app_setting.reload.mcp_server_settings['enabled']).to be false
      end
    end

    context 'when instance_level_ai_beta_features_enabled is false' do
      let!(:app_setting) do
        application_settings.create!(
          duo_features_enabled: true,
          instance_level_ai_beta_features_enabled: false,
          mcp_server_settings: { 'enabled' => true }
        )
      end

      it 'sets mcp_server_settings enabled to false' do
        migrate!

        expect(app_setting.reload.mcp_server_settings['enabled']).to be false
      end
    end
  end

  describe '#down' do
    let!(:app_setting) do
      application_settings.create!(
        duo_features_enabled: false,
        instance_level_ai_beta_features_enabled: false,
        mcp_server_settings: { 'enabled' => false }
      )
    end

    it 'resets mcp_server_settings enabled to true' do
      migrate!
      schema_migrate_down!

      expect(app_setting.reload.mcp_server_settings['enabled']).to be true
    end
  end
end
