# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::HealthStatus::Indicators::PatroniApdex, :aggregate_failures, feature_category: :database do # rubocop:disable Layout/LineLength
  let(:schema) { :main }
  let(:connection) { Gitlab::Database.database_base_models[schema].connection }

  around do |example|
    Gitlab::Database::SharedModel.using_connection(connection) do
      example.run
    end
  end

  describe '#evaluate' do
    let(:prometheus_url) { 'http://thanos:9090' }
    let(:prometheus_config) { [prometheus_url, { allow_local_requests: true, verify: true }] }

    let(:prometheus_client) { instance_double(Gitlab::PrometheusClient) }

    let(:context) do
      Gitlab::Database::BackgroundMigration::HealthStatus::Context
        .new(connection, ['users'], gitlab_schema)
    end

    let(:gitlab_schema) { "gitlab_#{schema}" }
    let(:client_ready) { true }
    let(:database_apdex_sli_query_main) { 'Apdex query for main' }
    let(:database_apdex_sli_query_ci) { 'Apdex query for ci' }
    let(:database_apdex_slo_main) { 0.99 }
    let(:database_apdex_slo_ci) { 0.95 }
    let(:database_apdex_settings) do
      {
        prometheus_api_url: prometheus_url,
        apdex_sli_query: {
          main: database_apdex_sli_query_main,
          ci: database_apdex_sli_query_ci
        },
        apdex_slo: {
          main: database_apdex_slo_main,
          ci: database_apdex_slo_ci
        }
      }
    end

    subject(:evaluate) { described_class.new(context).evaluate }

    before do
      stub_application_setting(database_apdex_settings: database_apdex_settings)

      allow(Gitlab::PrometheusClient).to receive(:new).with(*prometheus_config).and_return(prometheus_client)
      allow(prometheus_client).to receive(:ready?).and_return(client_ready)
    end

    shared_examples 'Patroni Apdex Evaluator' do |schema|
      context "with #{schema} schema" do
        let(:schema) { schema }
        let(:apdex_slo_above_sli) { { main: 0.991, ci: 0.951 } }
        let(:apdex_slo_below_sli) { { main: 0.989, ci: 0.949 } }

        it 'returns NoSignal signal in case the feature flag is disabled' do
          stub_feature_flags(batched_migrations_health_status_patroni_apdex: false)

          expect(evaluate).to be_a(Gitlab::Database::BackgroundMigration::HealthStatus::Signals::NotAvailable)
          expect(evaluate.reason).to include('indicator disabled')
        end

        context 'without database_apdex_settings' do
          let(:database_apdex_settings) { nil }

          it 'returns Unknown signal' do
            expect(evaluate).to be_a(Gitlab::Database::BackgroundMigration::HealthStatus::Signals::Unknown)
            expect(evaluate.reason).to include('Patroni Apdex Settings not configured')
          end
        end

        context 'when Prometheus client is not ready' do
          let(:client_ready) { false }

          it 'returns Unknown signal' do
            expect(evaluate).to be_a(Gitlab::Database::BackgroundMigration::HealthStatus::Signals::Unknown)
            expect(evaluate.reason).to include('Prometheus client is not ready')
          end
        end

        context 'when apdex SLI query is not configured' do
          let(:"database_apdex_sli_query_#{schema}") { nil }

          it 'returns Unknown signal' do
            expect(evaluate).to be_a(Gitlab::Database::BackgroundMigration::HealthStatus::Signals::Unknown)
            expect(evaluate.reason).to include('Apdex SLI query is not configured')
          end
        end

        context 'when slo is not configured' do
          let(:"database_apdex_slo_#{schema}") { nil }

          it 'returns Unknown signal' do
            expect(evaluate).to be_a(Gitlab::Database::BackgroundMigration::HealthStatus::Signals::Unknown)
            expect(evaluate.reason).to include('Apdex SLO is not configured')
          end
        end

        it 'returns Normal signal when Patroni apdex SLI is above SLO' do
          expect(prometheus_client).to receive(:query)
            .with(send("database_apdex_sli_query_#{schema}"))
            .and_return([{ "value" => [1662423310.878, apdex_slo_above_sli[schema]] }])
          expect(evaluate).to be_a(Gitlab::Database::BackgroundMigration::HealthStatus::Signals::Normal)
          expect(evaluate.reason).to include('Patroni service apdex is above SLO')
        end

        it 'returns Stop signal when Patroni apdex is below SLO' do
          expect(prometheus_client).to receive(:query)
            .with(send("database_apdex_sli_query_#{schema}"))
            .and_return([{ "value" => [1662423310.878, apdex_slo_below_sli[schema]] }])
          expect(evaluate).to be_a(Gitlab::Database::BackgroundMigration::HealthStatus::Signals::Stop)
          expect(evaluate.reason).to include('Patroni service apdex is below SLO')
        end

        context 'when Patroni apdex can not be calculated' do
          where(:result) do
            [
              nil,
              [],
              [{}],
              [{ 'value' => 1 }],
              [{ 'value' => [1] }]
            ]
          end

          with_them do
            it 'returns Unknown signal' do
              expect(prometheus_client).to receive(:query).and_return(result)
              expect(evaluate).to be_a(Gitlab::Database::BackgroundMigration::HealthStatus::Signals::Unknown)
              expect(evaluate.reason).to include('Patroni service apdex can not be calculated')
            end
          end
        end
      end
    end

    Gitlab::Database.database_base_models.each do |database_base_model, connection|
      next unless connection.present?

      it_behaves_like 'Patroni Apdex Evaluator', database_base_model.to_sym
    end
  end
end
