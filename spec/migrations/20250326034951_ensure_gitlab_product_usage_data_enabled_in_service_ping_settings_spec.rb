# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe EnsureGitlabProductUsageDataEnabledInServicePingSettings, feature_category: :database do
  let(:application_settings_table) { table(:application_settings) }

  describe '#up' do
    context 'when there are no application settings' do
      it 'does not raise an error' do
        expect { migrate! }.not_to raise_error
      end
    end

    context 'when snowplow_enabled is TRUE' do
      let!(:application_settings) do
        application_settings_table.create!(snowplow_enabled: true)
      end

      it 'sets gitlab_product_usage_data_enabled to FALSE' do
        expect { migrate! }
          .to change { application_settings.reload.service_ping_settings }
          .from({})
          .to({ 'gitlab_product_usage_data_enabled' => false })
      end

      context 'and service_ping_settings has existing values' do
        before do
          application_settings_table.update!(
            service_ping_settings: { 'existing_setting' => 'value' }
          )
        end

        it 'preserves existing settings and sets gitlab_product_usage_data_enabled to FALSE' do
          expect { migrate! }
            .to change { application_settings.reload.service_ping_settings }
            .from({ 'existing_setting' => 'value' })
            .to({ 'existing_setting' => 'value', 'gitlab_product_usage_data_enabled' => false })
        end
      end
    end

    context 'when snowplow_enabled is FALSE' do
      let!(:application_settings) do
        application_settings_table.create!(snowplow_enabled: false)
      end

      it 'sets gitlab_product_usage_data_enabled to TRUE' do
        expect { migrate! }
          .to change { application_settings.reload.service_ping_settings }
          .from({})
          .to({ 'gitlab_product_usage_data_enabled' => true })
      end

      context 'and service_ping_settings has existing values' do
        before do
          application_settings_table.update!(
            service_ping_settings: { 'existing_setting' => 'value' }
          )
        end

        it 'preserves existing settings and sets gitlab_product_usage_data_enabled to TRUE' do
          expect { migrate! }
            .to change { application_settings.reload.service_ping_settings }
            .from({ 'existing_setting' => 'value' })
            .to({ 'existing_setting' => 'value', 'gitlab_product_usage_data_enabled' => true })
        end
      end
    end

    context 'when working with default snowplow_enabled value' do
      let!(:application_settings) do
        application_settings_table.create!(snowplow_enabled: false)
      end

      it 'sets gitlab_product_usage_data_enabled to TRUE' do
        expect { migrate! }
          .to change { application_settings.reload.service_ping_settings }
          .from({})
          .to({ 'gitlab_product_usage_data_enabled' => true })
      end
    end

    context 'with multiple application settings records' do
      let!(:application_settings1) do
        application_settings_table.create!(snowplow_enabled: true)
      end

      let!(:application_settings2) do
        application_settings_table.create!(snowplow_enabled: false)
      end

      it 'updates all records according to their snowplow_enabled value' do
        migrate!

        expect(application_settings1.reload.service_ping_settings)
          .to eq({ 'gitlab_product_usage_data_enabled' => false })

        expect(application_settings2.reload.service_ping_settings)
          .to eq({ 'gitlab_product_usage_data_enabled' => true })
      end
    end
  end

  describe '#down' do
    it 'is a no-op' do
      application_settings_table.create!(
        snowplow_enabled: true,
        service_ping_settings: { 'gitlab_product_usage_data_enabled' => false }
      )

      schema_migrate_down!

      expect(application_settings_table.first.service_ping_settings)
        .to eq({ 'gitlab_product_usage_data_enabled' => false })
    end
  end
end
