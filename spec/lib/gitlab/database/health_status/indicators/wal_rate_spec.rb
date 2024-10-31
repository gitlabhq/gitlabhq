# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::HealthStatus::Indicators::WalRate, :aggregate_failures, feature_category: :database do
  it_behaves_like 'Prometheus Alert based health indicator' do
    let(:feature_flag) { :db_health_check_wal_rate }
    let(:sli_query_main) { 'WAL rate query for main' }
    let(:sli_query_ci) { 'WAL rate query for ci' }
    let(:slo_main) { 100 }
    let(:slo_ci) { 100 }
    let(:sli_with_good_condition) { { main: 70, ci: 70 } }
    let(:sli_with_bad_condition) { { main: 120, ci: 120 } }

    let(:prometheus_alert_db_indicators_settings) do
      {
        prometheus_api_url: prometheus_url,
        mimir_api_url: mimir_url,
        wal_rate_sli_query: {
          main: sli_query_main,
          ci: sli_query_ci
        },
        wal_rate_slo: {
          main: slo_main,
          ci: slo_ci
        }
      }
    end
  end
end
