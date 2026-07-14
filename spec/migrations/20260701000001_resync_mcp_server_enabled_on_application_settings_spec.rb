# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ResyncMcpServerEnabledOnApplicationSettings, migration: :gitlab_main, feature_category: :mcp_server do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    context 'when mcp_server_enabled is stale true (duo_features_enabled became false)' do
      let!(:app_setting) do
        application_settings.create!(
          duo_features_enabled: false,
          instance_level_ai_beta_features_enabled: true,
          mcp_server_settings: { 'mcp_server_enabled' => true }
        )
      end

      it 'sets mcp_server_enabled to false' do
        migrate!

        expect(app_setting.reload.mcp_server_settings['mcp_server_enabled']).to be false
      end
    end

    context 'when mcp_server_enabled is stale true (instance_level_ai_beta_features_enabled became false)' do
      let!(:app_setting) do
        application_settings.create!(
          duo_features_enabled: true,
          instance_level_ai_beta_features_enabled: false,
          mcp_server_settings: { 'mcp_server_enabled' => true }
        )
      end

      it 'sets mcp_server_enabled to false' do
        migrate!

        expect(app_setting.reload.mcp_server_settings['mcp_server_enabled']).to be false
      end
    end

    context 'when mcp_server_enabled is stale false (both prerequisites became true)' do
      let!(:app_setting) do
        application_settings.create!(
          duo_features_enabled: true,
          instance_level_ai_beta_features_enabled: true,
          mcp_server_settings: { 'mcp_server_enabled' => false }
        )
      end

      it 'sets mcp_server_enabled to true' do
        migrate!

        expect(app_setting.reload.mcp_server_settings['mcp_server_enabled']).to be true
      end
    end

    context 'when mcp_server_enabled is already correct' do
      let!(:app_setting) do
        application_settings.create!(
          duo_features_enabled: true,
          instance_level_ai_beta_features_enabled: true,
          mcp_server_settings: { 'mcp_server_enabled' => true }
        )
      end

      it 'does not update the row' do
        expect { migrate! }.not_to(
          change { app_setting.reload.updated_at }
        )
      end
    end
  end
end
