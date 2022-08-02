# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::BackgroundTransaction do
  let(:transaction) { described_class.new }

  describe '#run' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Metric, base_labels: {}) }

    before do
      allow(described_class).to receive(:prometheus_metric).and_return(prometheus_metric)
    end

    it 'yields the supplied block' do
      expect { |b| transaction.run(&b) }.to yield_control
    end

    it 'stores the transaction in the current thread' do
      transaction.run do
        expect(Thread.current[described_class::THREAD_KEY]).to eq(transaction)
      end
    end

    it 'removes the transaction from the current thread upon completion' do
      transaction.run {}

      expect(Thread.current[described_class::THREAD_KEY]).to be_nil
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

  it_behaves_like 'transaction metrics with labels' do
    let(:transaction_obj) { described_class.new }
    let(:labels) { { endpoint_id: 'TestWorker', feature_category: 'projects', queue: 'test_worker' } }

    before do
      test_worker_class = Class.new do
        def self.queue
          'test_worker'
        end
      end
      stub_const('TestWorker', test_worker_class)
    end

    around do |example|
      Gitlab::ApplicationContext.with_raw_context(feature_category: 'projects', caller_id: 'TestWorker') do
        example.run
      end
    end
  end
end
