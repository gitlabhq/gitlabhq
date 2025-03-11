# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveProductUsageDataEnabledFromServicePingSettings, :migration, feature_category: :application_instrumentation do
  let(:migration) { described_class.new }

  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    context 'when service_ping_settings contains product_usage_data_enabled' do
      before do
        application_settings.create!(
          service_ping_settings: { 'product_usage_data_enabled' => true, 'other_setting' => 'value' },
          updated_at: 1.hour.ago
        )
      end

      it 'removes the product_usage_data_enabled field' do
        expect { migration.up }.to change {
          application_settings.first.service_ping_settings
        }.from(
          { 'product_usage_data_enabled' => true, 'other_setting' => 'value' }
        ).to(
          { 'other_setting' => 'value' }
        )
      end

      it 'updates the updated_at timestamp' do
        original_time = application_settings.first.updated_at

        freeze_time do
          expect { migration.up }.to change {
            application_settings.first.updated_at
          }.from(original_time).to(Time.current)
        end
      end
    end
  end
end
