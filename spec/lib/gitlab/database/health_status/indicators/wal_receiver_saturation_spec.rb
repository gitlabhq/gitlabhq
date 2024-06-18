# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::HealthStatus::Indicators::WalReceiverSaturation, :aggregate_failures, feature_category: :database do
  it_behaves_like 'Prometheus Alert based health indicator' do
    let(:feature_flag) { :db_health_check_wal_receiver_saturation }
    let(:sli_query_main) { 'WAL receiver saturation query for main' }
    let(:sli_query_ci) { 'WAL receiver saturation query for ci' }
    let(:slo_main) { 0.9 }
    let(:slo_ci) { 0.9 }
    let(:sli_with_good_condition) { { main: 0.7, ci: 0.7 } }
    let(:sli_with_bad_condition) { { main: 0.95, ci: 0.96 } }

    let(:prometheus_alert_db_indicators_settings) do
      {
        prometheus_api_url: prometheus_url,
        mimir_api_url: mimir_url,
        wal_receiver_saturation_sli_query: {
          main: sli_query_main,
          ci: sli_query_ci
        },
        wal_receiver_saturation_slo: {
          main: slo_main,
          ci: slo_ci
        }
      }
    end
  end
end
