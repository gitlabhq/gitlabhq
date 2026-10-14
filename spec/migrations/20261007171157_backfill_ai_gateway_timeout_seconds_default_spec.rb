# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillAiGatewayTimeoutSecondsDefault,
  migration: :gitlab_main,
  feature_category: :ai_abstraction_layer do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    it 'updates rows with the old default of 60 to 120' do
      setting = application_settings.create!(ai_gateway_timeout_seconds: 60)

      migrate!

      expect(setting.reload.ai_gateway_timeout_seconds).to eq(120)
    end

    it 'does not change rows already set to a non-default value' do
      setting = application_settings.create!(ai_gateway_timeout_seconds: 90)

      migrate!

      expect(setting.reload.ai_gateway_timeout_seconds).to eq(90)
    end
  end

  describe '#down' do
    it 'does not revert backfilled rows' do
      setting = application_settings.create!(ai_gateway_timeout_seconds: 60)

      migrate!
      schema_migrate_down!

      expect(setting.reload.ai_gateway_timeout_seconds).to eq(120)
    end
  end
end
