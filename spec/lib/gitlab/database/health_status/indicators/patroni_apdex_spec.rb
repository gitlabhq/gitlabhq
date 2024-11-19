# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::HealthStatus::Indicators::PatroniApdex, :aggregate_failures,
  feature_category: :database do
  it_behaves_like 'Prometheus Alert based health indicator' do
    let(:feature_flag) { :batched_migrations_health_status_patroni_apdex }
    let(:sli_query_main) { 'Apdex query for main' }
    let(:sli_query_ci) { 'Apdex query for ci' }
    let(:slo_main) { 0.99 }
    let(:slo_ci) { 0.95 }
    let(:sli_with_good_condition) { { main: 0.991, ci: 0.951 } }
    let(:sli_with_bad_condition) { { main: 0.989, ci: 0.949 } }

    let(:prometheus_alert_db_indicators_settings) do
      {
        prometheus_api_url: prometheus_url,
        mimir_api_url: mimir_url,
        apdex_sli_query: {
          main: sli_query_main,
          ci: sli_query_ci
        },
        apdex_slo: {
          main: slo_main,
          ci: slo_ci
        }
      }
    end
  end
end
