# frozen_string_literal: true

require "spec_helper"
require_migration!

RSpec.describe BackfillProductAnalyticsDataCollectorHost, feature_category: :product_analytics do
  let!(:application_settings) { table(:application_settings) }

  describe '#up' do
    before do
      create_application_settings!(id: 1, jitsu_host: "https://configurator.testing.my-product-analytics.com",
        product_analytics_data_collector_host: nil)
      create_application_settings!(id: 2, jitsu_host: "https://config-urator_1.testing.my-product-analytics.com",
        product_analytics_data_collector_host: nil)
      create_application_settings!(id: 3, jitsu_host: "https://configurator.testing.my-product-analytics.com",
        product_analytics_data_collector_host: "https://existingcollector.my-product-analytics.com")
      create_application_settings!(id: 4, jitsu_host: nil, product_analytics_data_collector_host: nil)
      migrate!
    end

    describe 'when jitsu host is present' do
      it 'backfills missing product_analytics_data_collector_host' do
        expect(application_settings.find(1).product_analytics_data_collector_host).to eq("https://collector.testing.my-product-analytics.com")
        expect(application_settings.find(2).product_analytics_data_collector_host).to eq("https://collector.testing.my-product-analytics.com")
      end

      it 'does not modify existing product_analytics_data_collector_host' do
        expect(application_settings.find(3).product_analytics_data_collector_host).to eq("https://existingcollector.my-product-analytics.com")
      end
    end

    describe 'when jitsu host is not present' do
      it 'does not backfill product_analytics_data_collector_host' do
        expect(application_settings.find(4).product_analytics_data_collector_host).to be_nil
      end
    end
  end

  def create_application_settings!(id:, jitsu_host:, product_analytics_data_collector_host:)
    params = {
      id: id,
      jitsu_host: jitsu_host,
      product_analytics_data_collector_host: product_analytics_data_collector_host
    }
    application_settings.create!(params)
  end
end
