# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RestoreAiInfrastructureSettingsFromAiSettings,
  migration: :gitlab_main,
  feature_category: :ai_abstraction_layer do
  let(:ai_settings) { table(:ai_settings) }
  let(:application_settings) { table(:application_settings) }
  let(:organizations) { table(:organizations) }
  let(:default_organization_id) { 1 }

  describe '#up' do
    before do
      organizations.create!(id: default_organization_id, name: 'Default', path: 'default')
    end

    it 'restores settings left at their defaults from the default organization AI settings', :aggregate_failures do
      setting = application_settings.create!
      ai_settings.create!(
        organization_id: default_organization_id,
        ai_gateway_url: 'https://ai-gateway.example.com',
        ai_gateway_timeout_seconds: 30,
        enabled_instance_verbose_ai_logs: true,
        duo_agent_platform_service_url: 'https://duo-agent.example.com',
        self_hosted_duo_agent_platform_service_secure: false
      )

      migrate!

      setting.reload
      expect(setting.ai_gateway_url).to eq('https://ai-gateway.example.com')
      expect(setting.ai_gateway_timeout_seconds).to eq(30)
      expect(setting.enabled_instance_verbose_ai_logs).to be(true)
      expect(setting.duo_agent_platform_service_url).to eq('https://duo-agent.example.com')
      expect(setting.self_hosted_duo_agent_platform_service_secure).to be(false)
    end

    it 'preserves non-default settings entered after the upgrade', :aggregate_failures do
      setting = application_settings.create!(
        ai_gateway_url: 'https://current-ai-gateway.example.com',
        ai_gateway_timeout_seconds: 90,
        enabled_instance_verbose_ai_logs: true,
        duo_agent_platform_service_url: 'https://current-duo-agent.example.com',
        self_hosted_duo_agent_platform_service_secure: false
      )
      ai_settings.create!(
        organization_id: default_organization_id,
        ai_gateway_url: 'https://old-ai-gateway.example.com',
        ai_gateway_timeout_seconds: 30,
        enabled_instance_verbose_ai_logs: false,
        duo_agent_platform_service_url: 'https://old-duo-agent.example.com',
        self_hosted_duo_agent_platform_service_secure: true
      )

      migrate!

      setting.reload
      expect(setting.ai_gateway_url).to eq('https://current-ai-gateway.example.com')
      expect(setting.ai_gateway_timeout_seconds).to eq(90)
      expect(setting.enabled_instance_verbose_ai_logs).to be(true)
      expect(setting.duo_agent_platform_service_url).to eq('https://current-duo-agent.example.com')
      expect(setting.self_hosted_duo_agent_platform_service_secure).to be(false)
    end

    it 'restores only settings that were not re-entered after the upgrade', :aggregate_failures do
      setting = application_settings.create!(
        ai_gateway_url: 'https://current-ai-gateway.example.com',
        enabled_instance_verbose_ai_logs: true
      )
      ai_settings.create!(
        organization_id: default_organization_id,
        ai_gateway_url: 'https://old-ai-gateway.example.com',
        ai_gateway_timeout_seconds: 30,
        enabled_instance_verbose_ai_logs: true,
        duo_agent_platform_service_url: 'https://old-duo-agent.example.com',
        self_hosted_duo_agent_platform_service_secure: false
      )

      migrate!

      setting.reload
      expect(setting.ai_gateway_url).to eq('https://current-ai-gateway.example.com')
      expect(setting.ai_gateway_timeout_seconds).to eq(30)
      expect(setting.enabled_instance_verbose_ai_logs).to be(true)
      expect(setting.duo_agent_platform_service_url).to eq('https://old-duo-agent.example.com')
      expect(setting.self_hosted_duo_agent_platform_service_secure).to be(false)
    end

    it 'does not change settings when no default organization AI settings exist', :aggregate_failures do
      setting = application_settings.create!

      migrate!

      setting.reload
      expect(setting.ai_gateway_url).to be_nil
      expect(setting.ai_gateway_timeout_seconds).to eq(60)
      expect(setting.enabled_instance_verbose_ai_logs).to be(false)
      expect(setting.duo_agent_platform_service_url).to be_nil
      expect(setting.self_hosted_duo_agent_platform_service_secure).to be(true)
    end
  end
end
