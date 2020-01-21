# frozen_string_literal: true

require 'spec_helper'

describe Prometheus::ProxyService do
  include ReactiveCachingHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }

  describe 'configuration' do
    it 'ReactiveCaching refresh is not needed' do
      expect(described_class.reactive_cache_refresh_interval).to be > described_class.reactive_cache_lifetime
    end
  end

  describe '#initialize' do
    let(:params) { ActionController::Parameters.new(query: '1').permit! }

    it 'initializes attributes' do
      result = described_class.new(environment, 'GET', 'query', params)

      expect(result.proxyable).to eq(environment)
      expect(result.method).to eq('GET')
      expect(result.path).to eq('query')
      expect(result.params).to eq('query' => '1')
    end

    it 'converts ActionController::Parameters into hash' do
      result = described_class.new(environment, 'GET', 'query', params)

      expect(result.params).to be_an_instance_of(Hash)
    end

    context 'with unknown params' do
      let(:params) { ActionController::Parameters.new(query: '1', other_param: 'val').permit! }

      it 'filters unknown params' do
        result = described_class.new(environment, 'GET', 'query', params)

        expect(result.params).to eq('query' => '1')
      end
    end
  end

  describe '#execute' do
    let(:prometheus_adapter) { instance_double(PrometheusService) }
    let(:params) { ActionController::Parameters.new(query: '1').permit! }

    subject { described_class.new(environment, 'GET', 'query', params) }

    context 'when prometheus_adapter is nil' do
      before do
        allow(environment).to receive(:prometheus_adapter).and_return(nil)
      end

      it 'returns error' do
        expect(subject.execute).to eq(
          status: :error,
          message: 'No prometheus server found',
          http_status: :service_unavailable
        )
      end
    end

    context 'when prometheus_adapter cannot query' do
      before do
        allow(environment).to receive(:prometheus_adapter).and_return(prometheus_adapter)
        allow(prometheus_adapter).to receive(:can_query?).and_return(false)
      end

      it 'returns error' do
        expect(subject.execute).to eq(
          status: :error,
          message: 'No prometheus server found',
          http_status: :service_unavailable
        )
      end
    end

    context 'cannot proxy' do
      subject { described_class.new(environment, 'POST', 'garbage', params) }

      it 'returns error' do
        expect(subject.execute).to eq(
          message: 'Proxy support for this API is not available currently',
          status: :error
        )
      end
    end

    context 'with caching', :use_clean_rails_memory_store_caching do
      let(:return_value) { { 'http_status' => 200, 'body' => 'body' } }

      let(:opts) do
        [environment.class.name, environment.id, 'GET', 'query', { 'query' => '1' }]
      end

      before do
        allow(environment).to receive(:prometheus_adapter)
          .and_return(prometheus_adapter)
        allow(prometheus_adapter).to receive(:can_query?).and_return(true)
      end

      context 'when value present in cache' do
        before do
          stub_reactive_cache(subject, return_value, opts)
        end

        it 'returns cached value' do
          result = subject.execute

          expect(result[:http_status]).to eq(return_value[:http_status])
          expect(result[:body]).to eq(return_value[:body])
        end
      end

      context 'when value not present in cache' do
        it 'returns nil' do
          expect(ReactiveCachingWorker)
            .to receive(:perform_async)
            .with(subject.class, subject.id, *opts)

          result = subject.execute

          expect(result).to eq(nil)
        end
      end
    end

    context 'call prometheus api' do
      let(:prometheus_client) { instance_double(Gitlab::PrometheusClient) }

      before do
        synchronous_reactive_cache(subject)

        allow(environment).to receive(:prometheus_adapter)
          .and_return(prometheus_adapter)
        allow(prometheus_adapter).to receive(:can_query?).and_return(true)
        allow(prometheus_adapter).to receive(:prometheus_client)
          .and_return(prometheus_client)
      end

      context 'connection to prometheus server succeeds' do
        let(:rest_client_response) { instance_double(RestClient::Response) }
        let(:prometheus_http_status_code) { 400 }

        let(:response_body) do
          '{"status":"error","errorType":"bad_data","error":"parse error at char 1: no expression found in input"}'
        end

        before do
          allow(prometheus_client).to receive(:proxy).and_return(rest_client_response)

          allow(rest_client_response).to receive(:code)
            .and_return(prometheus_http_status_code)
          allow(rest_client_response).to receive(:body).and_return(response_body)
        end

        it 'returns the http status code and body from prometheus' do
          expect(subject.execute).to eq(
            http_status: prometheus_http_status_code,
            body: response_body,
            status: :success
          )
        end
      end

      context 'connection to prometheus server fails' do
        context 'prometheus client raises Gitlab::PrometheusClient::Error' do
          before do
            allow(prometheus_client).to receive(:proxy)
              .and_raise(Gitlab::PrometheusClient::Error, 'Network connection error')
          end

          it 'returns error' do
            expect(subject.execute).to eq(
              status: :error,
              message: 'Network connection error',
              http_status: :service_unavailable
            )
          end
        end
      end
    end
  end

  describe '.from_cache' do
    it 'initializes an instance of ProxyService class' do
      result = described_class.from_cache(
        environment.class.name, environment.id, 'GET', 'query', { 'query' => '1' }
      )

      expect(result).to be_an_instance_of(described_class)
      expect(result.proxyable).to eq(environment)
      expect(result.method).to eq('GET')
      expect(result.path).to eq('query')
      expect(result.params).to eq('query' => '1')
    end
  end
end
