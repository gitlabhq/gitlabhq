# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillAiInfrastructureSettingsFromAiSettings,
  migration: :gitlab_main,
  feature_category: :ai_abstraction_layer do
  let(:ai_settings) { table(:ai_settings) }
  let(:application_settings) { table(:application_settings) }
  let(:default_organization_id) { 1 }

  describe '#up' do
    it 'copies values from the default organization ai_settings row', :aggregate_failures do
      setting = application_settings.create!

      ai_settings.create!(
        organization_id: default_organization_id,
        ai_gateway_url: 'https://ai-gateway.example.com',
        ai_gateway_timeout_seconds: 30,
        enabled_instance_verbose_ai_logs: true,
        duo_agent_platform_service_url: 'https://duo-agent.example.com',
        self_hosted_duo_agent_platform_service_secure: true
      )

      migrate!

      setting.reload
      expect(setting.ai_gateway_url).to eq('https://ai-gateway.example.com')
      expect(setting.ai_gateway_timeout_seconds).to eq(30)
      expect(setting.enabled_instance_verbose_ai_logs).to be(true)
      expect(setting.duo_agent_platform_service_url).to eq('https://duo-agent.example.com')
      expect(setting.self_hosted_duo_agent_platform_service_secure).to be(true)
    end

    it 'uses fallback values when source values are nil', :aggregate_failures do
      setting = application_settings.create!

      allow_nil_self_hosted_duo_agent_platform_service_secure do
        ai_settings.create!(
          organization_id: default_organization_id,
          ai_gateway_timeout_seconds: nil,
          enabled_instance_verbose_ai_logs: nil,
          self_hosted_duo_agent_platform_service_secure: nil
        )

        migrate!
      end

      setting.reload
      expect(setting.ai_gateway_timeout_seconds).to eq(60)
      expect(setting.enabled_instance_verbose_ai_logs).to be(false)
      expect(setting.self_hosted_duo_agent_platform_service_secure).to be(true)
    end

    it 'keeps false self_hosted_duo_agent_platform_service_secure value as false' do
      setting = application_settings.create!

      ai_settings.create!(
        organization_id: default_organization_id,
        self_hosted_duo_agent_platform_service_secure: false
      )

      migrate!

      expect(setting.reload.self_hosted_duo_agent_platform_service_secure).to be(false)
    end

    it 'leaves application_settings unchanged when no default organization ai_settings row exists',
      :aggregate_failures do
      setting = application_settings.create!(
        ai_gateway_url: 'https://existing-ai-gateway.example.com',
        ai_gateway_timeout_seconds: 45,
        enabled_instance_verbose_ai_logs: true,
        duo_agent_platform_service_url: 'https://existing-duo-agent.example.com',
        self_hosted_duo_agent_platform_service_secure: false
      )

      ai_settings.create!(
        organization_id: default_organization_id + 1,
        ai_gateway_url: 'https://ignored-ai-gateway.example.com',
        ai_gateway_timeout_seconds: 30,
        enabled_instance_verbose_ai_logs: false,
        duo_agent_platform_service_url: 'https://ignored-duo-agent.example.com',
        self_hosted_duo_agent_platform_service_secure: true
      )

      migrate!

      setting.reload
      expect(setting.ai_gateway_url).to eq('https://existing-ai-gateway.example.com')
      expect(setting.ai_gateway_timeout_seconds).to eq(45)
      expect(setting.enabled_instance_verbose_ai_logs).to be(true)
      expect(setting.duo_agent_platform_service_url).to eq('https://existing-duo-agent.example.com')
      expect(setting.self_hosted_duo_agent_platform_service_secure).to be(false)
    end
  end

  def allow_nil_self_hosted_duo_agent_platform_service_secure
    connection = ai_settings.connection

    connection.change_column_null(:ai_settings, :self_hosted_duo_agent_platform_service_secure, true)
    yield
  ensure
    ai_settings.where(self_hosted_duo_agent_platform_service_secure: nil)
      .update_all(self_hosted_duo_agent_platform_service_secure: true)
    connection.change_column_null(:ai_settings, :self_hosted_duo_agent_platform_service_secure, false)
  end
end
