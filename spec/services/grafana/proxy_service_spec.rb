# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Grafana::ProxyService do
  include ReactiveCachingHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:grafana_integration) { create(:grafana_integration, project: project) }

  let(:proxy_path) { 'api/v1/query_range' }
  let(:datasource_id) { '1' }
  let(:query_params) do
    {
      'query' => 'rate(relevant_metric)',
      'start' => '1570441248',
      'end' => '1570444848',
      'step' => '900'
    }
  end

  let(:cache_params) { [project.id, datasource_id, proxy_path, query_params] }

  let(:service) do
    described_class.new(project, datasource_id, proxy_path, query_params)
  end

  shared_examples_for 'initializes an instance' do
    it 'initializes an instance of ProxyService class' do
      expect(subject).to be_an_instance_of(described_class)
      expect(subject.project).to eq(project)
      expect(subject.datasource_id).to eq('1')
      expect(subject.proxy_path).to eq('api/v1/query_range')
      expect(subject.query_params).to eq(query_params)
    end
  end

  describe '.from_cache' do
    subject { described_class.from_cache(*cache_params) }

    it_behaves_like 'initializes an instance'
  end

  describe '#initialize' do
    subject { service }

    it_behaves_like 'initializes an instance'
  end

  describe '#execute' do
    subject(:result) { service.execute }

    context 'when grafana integration is not configured' do
      before do
        allow(project).to receive(:grafana_integration).and_return(nil)
      end

      it 'returns error' do
        expect(result).to eq(
          status: :error,
          message: 'Proxy support for this API is not available currently'
        )
      end
    end

    context 'with caching', :use_clean_rails_memory_store_caching do
      context 'when value not present in cache' do
        it 'returns nil' do
          expect(ExternalServiceReactiveCachingWorker)
            .to receive(:perform_async)
            .with(service.class, service.id, *cache_params)

          expect(result).to eq(nil)
        end
      end

      context 'when value present in cache' do
        let(:return_value) { { 'http_status' => 200, 'body' => 'body' } }

        before do
          stub_reactive_cache(service, return_value, cache_params)
        end

        it 'returns cached value' do
          expect(ReactiveCachingWorker)
            .not_to receive(:perform_async)
            .with(service.class, service.id, *cache_params)

          expect(result[:http_status]).to eq(return_value[:http_status])
          expect(result[:body]).to eq(return_value[:body])
        end
      end
    end

    context 'call prometheus api' do
      let(:client) { service.send(:client) }

      before do
        synchronous_reactive_cache(service)
      end

      context 'connection to grafana datasource succeeds' do
        let(:response) { instance_double(Gitlab::HTTP::Response) }
        let(:status_code) { 400 }
        let(:body) { 'body' }

        before do
          allow(client).to receive(:proxy_datasource).and_return(response)

          allow(response).to receive(:code).and_return(status_code)
          allow(response).to receive(:body).and_return(body)
        end

        it 'returns the http status code and body from prometheus' do
          expect(result).to eq(
            http_status: status_code,
            body: body,
            status: :success
          )
        end
      end

      context 'connection to grafana datasource fails' do
        before do
          allow(client).to receive(:proxy_datasource)
            .and_raise(Grafana::Client::Error, 'Network connection error')
        end

        it 'returns error' do
          expect(result).to eq(
            status: :error,
            message: 'Network connection error',
            http_status: :service_unavailable
          )
        end
      end
    end
  end
end
