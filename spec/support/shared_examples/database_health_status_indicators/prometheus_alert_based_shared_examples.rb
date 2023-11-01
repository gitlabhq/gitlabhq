# frozen_string_literal: true

RSpec.shared_examples 'Prometheus Alert based health indicator' do
  let(:schema) { :main }
  let(:connection) { Gitlab::Database.database_base_models_with_gitlab_shared[schema].connection }

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
      Gitlab::Database::HealthStatus::Context.new(
        described_class,
        connection,
        ['users'],
        gitlab_schema
      )
    end

    let(:gitlab_schema) { "gitlab_#{schema}" }
    let(:client_ready) { true }
    let(:indicator_name) { described_class.name.demodulize }
    let(:indicator) { described_class.new(context) }

    subject(:evaluate) { indicator.evaluate }

    before do
      stub_application_setting(prometheus_alert_db_indicators_settings: prometheus_alert_db_indicators_settings)

      allow(Gitlab::PrometheusClient).to receive(:new).with(*prometheus_config).and_return(prometheus_client)
      allow(prometheus_client).to receive(:ready?).and_return(client_ready)
    end

    shared_examples 'Patroni Apdex Evaluator' do |schema|
      context "with #{schema} schema" do
        let(:schema) { schema }

        it 'returns NoSignal signal in case the feature flag is disabled' do
          stub_feature_flags(feature_flag => false)

          expect(evaluate).to be_a(Gitlab::Database::HealthStatus::Signals::NotAvailable)
          expect(evaluate.reason).to include('indicator disabled')
        end

        context 'without prometheus_alert_db_indicators_settings' do
          let(:prometheus_alert_db_indicators_settings) { nil }

          it 'returns Unknown signal' do
            expect(evaluate).to be_a(Gitlab::Database::HealthStatus::Signals::Unknown)
            expect(evaluate.reason).to include('Prometheus Settings not configured')
          end
        end

        context 'when Prometheus client is not ready' do
          let(:client_ready) { false }

          it 'returns Unknown signal' do
            expect(evaluate).to be_a(Gitlab::Database::HealthStatus::Signals::Unknown)
            expect(evaluate.reason).to include('Prometheus client is not ready')
          end
        end

        context 'when apdex SLI query is not configured' do
          let(:"sli_query_#{schema}") { nil }

          it 'returns Unknown signal' do
            expect(evaluate).to be_a(Gitlab::Database::HealthStatus::Signals::Unknown)
            expect(evaluate.reason).to include("#{indicator_name} SLI query is not configured")
          end
        end

        context 'when slo is not configured' do
          let(:"slo_#{schema}") { nil }

          it 'returns Unknown signal' do
            expect(evaluate).to be_a(Gitlab::Database::HealthStatus::Signals::Unknown)
            expect(evaluate.reason).to include("#{indicator_name} SLO is not configured")
          end
        end

        it 'returns Normal signal when SLI condition is met' do
          expect(prometheus_client).to receive(:query)
            .with(send("sli_query_#{schema}"))
            .and_return([{ "value" => [1662423310.878, sli_with_good_condition[schema]] }])
          expect(evaluate).to be_a(Gitlab::Database::HealthStatus::Signals::Normal)
          expect(evaluate.reason).to include("#{indicator_name} SLI condition met")
        end

        it 'returns Stop signal when SLI condition is not met' do
          expect(prometheus_client).to receive(:query)
            .with(send("sli_query_#{schema}"))
            .and_return([{ "value" => [1662423310.878, sli_with_bad_condition[schema]] }])
          expect(evaluate).to be_a(Gitlab::Database::HealthStatus::Signals::Stop)
          expect(evaluate.reason).to include("#{indicator_name} SLI condition not met")
        end

        context 'when SLI can not be calculated' do
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
              expect(evaluate).to be_a(Gitlab::Database::HealthStatus::Signals::Unknown)
              expect(evaluate.reason).to include("#{indicator_name} can not be calculated")
            end
          end
        end
      end
    end

    Gitlab::Database.database_base_models_with_gitlab_shared.each do |database_base_model, connection|
      next unless connection.present?

      it_behaves_like 'Patroni Apdex Evaluator', database_base_model.to_sym
    end
  end
end
