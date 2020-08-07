# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::ElasticsearchRackMiddleware do
  let(:app) { double(:app, call: 'app call result') }
  let(:middleware) { described_class.new(app) }
  let(:env) { {} }
  let(:transaction) { Gitlab::Metrics::WebTransaction.new(env) }

  describe '#call' do
    let(:elasticsearch_query_time) { 0.1 }
    let(:elasticsearch_requests_count) { 2 }

    before do
      allow(Gitlab::Instrumentation::ElasticsearchTransport).to receive(:query_time) { elasticsearch_query_time }
      allow(Gitlab::Instrumentation::ElasticsearchTransport).to receive(:get_request_count) { elasticsearch_requests_count }

      allow(Gitlab::Metrics).to receive(:current_transaction).and_return(transaction)
    end

    it 'calls the app' do
      expect(middleware.call(env)).to eq('app call result')
    end

    it 'records elasticsearch metrics' do
      expect(transaction).to receive(:increment).with(:http_elasticsearch_requests_total, elasticsearch_requests_count)
      expect(transaction).to receive(:observe).with(:http_elasticsearch_requests_duration_seconds, elasticsearch_query_time)

      middleware.call(env)
    end

    it 'records elasticsearch metrics if an error is raised' do
      expect(transaction).to receive(:increment).with(:http_elasticsearch_requests_total, elasticsearch_requests_count)
      expect(transaction).to receive(:observe).with(:http_elasticsearch_requests_duration_seconds, elasticsearch_query_time)

      allow(app).to receive(:call).with(env).and_raise(StandardError)

      expect { middleware.call(env) }.to raise_error(StandardError)
    end

    context 'when there are no elasticsearch requests' do
      let(:elasticsearch_requests_count) { 0 }

      it 'does not record any metrics' do
        expect(transaction).not_to receive(:observe).with(:http_elasticsearch_requests_duration_seconds)
        expect(transaction).not_to receive(:increment).with(:http_elasticsearch_requests_total, 0)

        middleware.call(env)
      end
    end
  end
end
