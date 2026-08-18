# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateWebHookRateLimitFlagsToApplicationSettings, feature_category: :webhooks do
  let(:application_settings) { table(:application_settings) }
  let(:features) { table(:features) }
  let(:feature_gates) { table(:feature_gates) }

  let!(:application_setting) { application_settings.create!(rate_limits: { 'members_delete_limit' => 60 }) }

  describe '#up' do
    context 'when the feature flags were never set' do
      it 'does not write the settings' do
        migrate!

        expect(application_setting.reload.rate_limits).to eq({ 'members_delete_limit' => 60 })
      end
    end

    context 'when the feature flags were explicitly enabled' do
      before do
        described_class::FLAG_TO_SETTING.each_key do |flag_name|
          features.create!(key: flag_name.to_s)
          feature_gates.create!(feature_key: flag_name.to_s, key: 'boolean', value: 'true')
        end
      end

      it 'does not write the settings' do
        migrate!

        expect(application_setting.reload.rate_limits).to eq({ 'members_delete_limit' => 60 })
      end
    end

    context 'when the feature flags have percentage or actor gates' do
      before do
        described_class::FLAG_TO_SETTING.each_key do |flag_name|
          features.create!(key: flag_name.to_s)
          feature_gates.create!(feature_key: flag_name.to_s, key: 'percentage_of_actors', value: '50')
        end
      end

      it 'does not write the settings' do
        migrate!

        expect(application_setting.reload.rate_limits).to eq({ 'members_delete_limit' => 60 })
      end
    end

    context 'when the feature flags were explicitly disabled' do
      before do
        described_class::FLAG_TO_SETTING.each_key do |flag_name|
          features.create!(key: flag_name.to_s)
          feature_gates.create!(feature_key: flag_name.to_s, key: 'boolean', value: 'false')
        end
      end

      it 'disables the rate limits and preserves other keys' do
        migrate!

        expect(application_setting.reload.rate_limits).to eq(
          {
            'members_delete_limit' => 60,
            'web_hook_event_resend_limit' => 0,
            'web_hook_test_limit' => 0
          }
        )
      end
    end

    context 'when only one feature flag was explicitly disabled' do
      before do
        features.create!(key: 'web_hook_test_api_endpoint_rate_limit')
        feature_gates.create!(feature_key: 'web_hook_test_api_endpoint_rate_limit', key: 'boolean', value: 'false')
      end

      it 'disables only the matching rate limit' do
        migrate!

        expect(application_setting.reload.rate_limits).to eq(
          {
            'members_delete_limit' => 60,
            'web_hook_test_limit' => 0
          }
        )
      end
    end
  end

  describe '#down' do
    context 'when the settings were written by the migration' do
      before do
        described_class::FLAG_TO_SETTING.each_key do |flag_name|
          features.create!(key: flag_name.to_s)
          feature_gates.create!(feature_key: flag_name.to_s, key: 'boolean', value: 'false')
        end
      end

      it 'removes the settings and preserves other keys' do
        migrate!

        schema_migrate_down!

        expect(application_setting.reload.rate_limits).to eq({ 'members_delete_limit' => 60 })
      end
    end

    context 'when the settings have pre-existing values not written by the migration' do
      before do
        application_setting.update!(
          rate_limits: {
            'members_delete_limit' => 60,
            'web_hook_event_resend_limit' => 10,
            'web_hook_test_limit' => 20
          }
        )
      end

      it 'removes the settings unconditionally' do
        migrate!

        schema_migrate_down!

        expect(application_setting.reload.rate_limits).to eq({ 'members_delete_limit' => 60 })
      end
    end
  end
end
