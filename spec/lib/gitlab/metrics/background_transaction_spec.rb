# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::BackgroundTransaction do
  let(:transaction) { described_class.new }
  let(:prometheus_metric) { instance_double(Prometheus::Client::Metric, base_labels: {}) }

  before do
    allow(described_class).to receive(:prometheus_metric).and_return(prometheus_metric)
  end

  describe '#run' do
    it 'yields the supplied block' do
      expect { |b| transaction.run(&b) }.to yield_control
    end

    it 'stores the transaction in the current thread' do
      transaction.run do
        expect(Thread.current[described_class::BACKGROUND_THREAD_KEY]).to eq(transaction)
      end
    end

    it 'removes the transaction from the current thread upon completion' do
      transaction.run { }

      expect(Thread.current[described_class::BACKGROUND_THREAD_KEY]).to be_nil
    end
  end

  describe '#labels' do
    context 'when the worker queue is accessible' do
      before do
        test_worker_class = Class.new do
          def self.queue
            'test_worker'
          end
        end
        stub_const('TestWorker', test_worker_class)
      end

      it 'provides labels with endpoint_id, feature_category and queue' do
        Gitlab::ApplicationContext.with_raw_context(feature_category: 'projects', caller_id: 'TestWorker') do
          expect(transaction.labels).to eq({ endpoint_id: 'TestWorker', feature_category: 'projects', queue: 'test_worker' })
        end
      end
    end

    context 'when the worker name does not exist' do
      it 'provides labels with endpoint_id and feature_category' do
        # 123TestWorker is an invalid constant
        Gitlab::ApplicationContext.with_raw_context(feature_category: 'projects', caller_id: '123TestWorker') do
          expect(transaction.labels).to eq({ endpoint_id: '123TestWorker', feature_category: 'projects', queue: nil })
        end
      end
    end

    context 'when the worker queue is not accessible' do
      before do
        stub_const('TestWorker', Class.new)
      end

      it 'provides labels with endpoint_id and feature_category' do
        Gitlab::ApplicationContext.with_raw_context(feature_category: 'projects', caller_id: 'TestWorker') do
          expect(transaction.labels).to eq({ endpoint_id: 'TestWorker', feature_category: 'projects', queue: nil })
        end
      end
    end
  end

  RSpec.shared_examples 'metric with labels' do |metric_method|
    before do
      test_worker_class = Class.new do
        def self.queue
          'test_worker'
        end
      end
      stub_const('TestWorker', test_worker_class)
    end

    it 'measures with correct labels and value' do
      value = 1
      expect(prometheus_metric).to receive(metric_method).with({
        endpoint_id: 'TestWorker', feature_category: 'projects', queue: 'test_worker'
      }, value)

      Gitlab::ApplicationContext.with_raw_context(feature_category: 'projects', caller_id: 'TestWorker') do
        transaction.send(metric_method, :test_metric, value)
      end
    end
  end

  describe '#increment' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Counter, :increment, base_labels: {}) }

    it_behaves_like 'metric with labels', :increment
  end

  describe '#set' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Gauge, :set, base_labels: {}) }

    it_behaves_like 'metric with labels', :set
  end

  describe '#observe' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Histogram, :observe, base_labels: {}) }

    it_behaves_like 'metric with labels', :observe
  end
end
