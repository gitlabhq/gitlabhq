# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillThrottleAuthenticatedGitHttpSettings, feature_category: :source_code_management do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    context 'when throttle_authenticated_web is enabled' do
      it 'copies settings to rate_limits when git_http throttle is not set' do
        setting = application_settings.create!(
          throttle_authenticated_web_enabled: true,
          throttle_authenticated_web_requests_per_period: 300,
          throttle_authenticated_web_period_in_seconds: 60,
          rate_limits: {}
        )

        migrate!

        setting.reload
        expect(setting.rate_limits['throttle_authenticated_git_http_enabled']).to be(true)
        expect(setting.rate_limits['throttle_authenticated_git_http_requests_per_period']).to eq(300)
        expect(setting.rate_limits['throttle_authenticated_git_http_period_in_seconds']).to eq(60)
      end

      it 'does not override existing git_http throttle settings' do
        setting = application_settings.create!(
          throttle_authenticated_web_enabled: true,
          throttle_authenticated_web_requests_per_period: 300,
          throttle_authenticated_web_period_in_seconds: 60,
          rate_limits: {
            'throttle_authenticated_git_http_enabled' => true,
            'throttle_authenticated_git_http_requests_per_period' => 500,
            'throttle_authenticated_git_http_period_in_seconds' => 120
          }
        )

        migrate!

        setting.reload
        expect(setting.rate_limits['throttle_authenticated_git_http_enabled']).to be(true)
        expect(setting.rate_limits['throttle_authenticated_git_http_requests_per_period']).to eq(500)
        expect(setting.rate_limits['throttle_authenticated_git_http_period_in_seconds']).to eq(120)
      end

      it 'copies settings when git_http throttle is explicitly disabled' do
        setting = application_settings.create!(
          throttle_authenticated_web_enabled: true,
          throttle_authenticated_web_requests_per_period: 300,
          throttle_authenticated_web_period_in_seconds: 60,
          rate_limits: {
            'other_setting' => true,
            'throttle_authenticated_git_http_enabled' => false,
            'throttle_authenticated_git_http_requests_per_period' => 35,
            'throttle_authenticated_git_http_period_in_seconds' => 35
          }
        )

        migrate!

        setting.reload
        expect(setting.rate_limits['throttle_authenticated_git_http_enabled']).to be(true)
        expect(setting.rate_limits['throttle_authenticated_git_http_requests_per_period']).to eq(300)
        expect(setting.rate_limits['throttle_authenticated_git_http_period_in_seconds']).to eq(60)

        expect(setting.rate_limits['other_setting']).to be(true)
      end

      it 'copies settings when git_http throttle is disabled but partially set' do
        setting = application_settings.create!(
          throttle_authenticated_web_enabled: true,
          throttle_authenticated_web_requests_per_period: 300,
          throttle_authenticated_web_period_in_seconds: 60,
          rate_limits: {
            'throttle_authenticated_git_http_requests_per_period' => 35,
            'throttle_authenticated_git_http_period_in_seconds' => 35
          }
        )

        migrate!

        setting.reload
        expect(setting.rate_limits['throttle_authenticated_git_http_enabled']).to be(true)
        expect(setting.rate_limits['throttle_authenticated_git_http_requests_per_period']).to eq(300)
        expect(setting.rate_limits['throttle_authenticated_git_http_period_in_seconds']).to eq(60)
      end
    end

    context 'when throttle_authenticated_web is disabled' do
      it 'does not copy settings' do
        setting = application_settings.create!(
          throttle_authenticated_web_enabled: false,
          throttle_authenticated_web_requests_per_period: 300,
          throttle_authenticated_web_period_in_seconds: 60,
          rate_limits: {}
        )

        migrate!

        setting.reload
        expect(setting.rate_limits['throttle_authenticated_git_http_enabled']).to be_nil
      end
    end
  end

  describe '#down' do
    it 'is a no-op' do
      setting = application_settings.create!(
        throttle_authenticated_web_enabled: true,
        throttle_authenticated_web_requests_per_period: 300,
        throttle_authenticated_web_period_in_seconds: 60,
        rate_limits: {}
      )

      migrate!

      setting.reload
      expect(setting.rate_limits['throttle_authenticated_git_http_enabled']).to be(true)

      schema_migrate_down!

      setting.reload
      expect(setting.rate_limits['throttle_authenticated_git_http_enabled']).to be(true)
      expect(setting.rate_limits['throttle_authenticated_git_http_requests_per_period']).to eq(300)
      expect(setting.rate_limits['throttle_authenticated_git_http_period_in_seconds']).to eq(60)
    end
  end
end
