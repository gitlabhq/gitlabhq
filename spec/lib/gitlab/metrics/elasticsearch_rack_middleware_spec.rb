# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::ElasticsearchRackMiddleware do
  let(:app) { double(:app, call: 'app call result') }
  let(:middleware) { described_class.new(app) }
  let(:env) { {} }
  let(:transaction) { Gitlab::Metrics::WebTransaction.new(env) }

  describe '#call' do
    let(:counter) { instance_double(Prometheus::Client::Counter, increment: nil) }
    let(:histogram) { instance_double(Prometheus::Client::Histogram, observe: nil) }
    let(:elasticsearch_query_time) { 0.1 }
    let(:elasticsearch_requests_count) { 2 }

    before do
      allow(Gitlab::Instrumentation::ElasticsearchTransport).to receive(:query_time) { elasticsearch_query_time }
      allow(Gitlab::Instrumentation::ElasticsearchTransport).to receive(:get_request_count) { elasticsearch_requests_count }

      allow(Gitlab::Metrics).to receive(:counter)
        .with(:http_elasticsearch_requests_total,
              an_instance_of(String),
              Gitlab::Metrics::Transaction::BASE_LABELS)
        .and_return(counter)

      allow(Gitlab::Metrics).to receive(:histogram)
        .with(:http_elasticsearch_requests_duration_seconds,
              an_instance_of(String),
              Gitlab::Metrics::Transaction::BASE_LABELS,
              described_class::HISTOGRAM_BUCKETS)
        .and_return(histogram)

      allow(Gitlab::Metrics).to receive(:current_transaction).and_return(transaction)
    end

    it 'calls the app' do
      expect(middleware.call(env)).to eq('app call result')
    end

    it 'records elasticsearch metrics' do
      expect(counter).to receive(:increment).with(transaction.labels, elasticsearch_requests_count)
      expect(histogram).to receive(:observe).with(transaction.labels, elasticsearch_query_time)

      middleware.call(env)
    end

    it 'records elasticsearch metrics if an error is raised' do
      expect(counter).to receive(:increment).with(transaction.labels, elasticsearch_requests_count)
      expect(histogram).to receive(:observe).with(transaction.labels, elasticsearch_query_time)

      allow(app).to receive(:call).with(env).and_raise(StandardError)

      expect { middleware.call(env) }.to raise_error(StandardError)
    end
  end
end
