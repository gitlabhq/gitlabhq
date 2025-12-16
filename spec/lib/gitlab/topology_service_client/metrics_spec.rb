# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::Metrics, feature_category: :cell do
  let(:cell_id) { '1' }
  let(:topology_service_address) { 'localhost:50051' }
  let(:metrics) { described_class.new(cell_id: cell_id, topology_service_address: topology_service_address) }

  before do
    allow(::Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(true)
    # Clear all memoization before each test to ensure fresh state
    described_class.clear_memoization(:rpc_duration_histogram)
    described_class.clear_memoization(:request_size_histogram)
    described_class.clear_memoization(:response_size_histogram)
    described_class.clear_memoization(:rpc_calls_total_counter)
    described_class.clear_memoization(:failed_calls_total_counter)
  end

  after do
    # Clear all memoization after each test to prevent mocks from leaking to subsequent tests
    described_class.clear_memoization(:rpc_duration_histogram)
    described_class.clear_memoization(:request_size_histogram)
    described_class.clear_memoization(:response_size_histogram)
    described_class.clear_memoization(:rpc_calls_total_counter)
    described_class.clear_memoization(:failed_calls_total_counter)
  end

  describe '#initialize' do
    it 'stores cell_id and topology_service_address' do
      expect(metrics.instance_variable_get(:@cell_id)).to eq(cell_id)
      expect(metrics.instance_variable_get(:@topology_service_address)).to eq(topology_service_address)
    end
  end

  describe '#observe_rpc_duration' do
    it 'records duration metric with correct labels' do
      histogram_mock = instance_double(Prometheus::Client::Histogram)
      allow(described_class).to receive(:rpc_duration_histogram).and_return(histogram_mock)
      allow(histogram_mock).to receive(:observe)

      labels = metrics.build_labels(service: 'CellService', method: 'GetCellInfo', status_code: 0)
      metrics.observe_rpc_duration(labels: labels, duration_seconds: 0.5)

      expect(histogram_mock).to have_received(:observe).with(
        hash_including(
          rpc_service: 'CellService',
          rpc_method: 'GetCellInfo',
          rpc_status: 'OK',
          cell_id: cell_id,
          topology_service_address: topology_service_address
        ),
        within(0.001).of(0.5)
      )
    end

    it 'gracefully handles metric recording failures' do
      allow(described_class).to receive(:rpc_duration_histogram).and_raise(StandardError.new('Metric error'))
      expect(Gitlab::AppLogger).to receive(:debug)

      expect do
        labels = metrics.build_labels(service: 'CellService', method: 'GetCellInfo', status_code: 0)
        metrics.observe_rpc_duration(labels: labels, duration_seconds: 0.5)
      end.not_to raise_error
    end
  end

  describe '#observe_request_size' do
    it 'records request size metric' do
      histogram_mock = instance_double(Prometheus::Client::Histogram)
      allow(described_class).to receive(:request_size_histogram).and_return(histogram_mock)
      allow(histogram_mock).to receive(:observe)

      labels = metrics.build_labels(service: 'CellService', method: 'GetCellInfo', status_code: 0)
      metrics.observe_request_size(labels: labels, size_bytes: 1024)

      expect(histogram_mock).to have_received(:observe).with(
        hash_including(
          rpc_service: 'CellService',
          rpc_method: 'GetCellInfo',
          rpc_status: 'OK'
        ),
        1024
      )
    end

    it 'gracefully handles metric recording failures' do
      histogram_mock = instance_double(Prometheus::Client::Histogram)
      allow(described_class).to receive(:request_size_histogram).and_return(histogram_mock)
      allow(histogram_mock).to receive(:observe).and_raise(StandardError.new('Histogram error'))
      expect(Gitlab::AppLogger).to receive(:debug).with(include('Failed to observe request size'))

      labels = metrics.build_labels(service: 'CellService', method: 'GetCellInfo', status_code: 0)
      expect do
        metrics.observe_request_size(labels: labels, size_bytes: 1024)
      end.not_to raise_error
    end
  end

  describe '#observe_response_size' do
    it 'records response size metric' do
      histogram_mock = instance_double(Prometheus::Client::Histogram)
      allow(described_class).to receive(:response_size_histogram).and_return(histogram_mock)
      allow(histogram_mock).to receive(:observe)

      labels = metrics.build_labels(service: 'CellService', method: 'GetCellInfo', status_code: 0)
      metrics.observe_response_size(labels: labels, size_bytes: 2048)

      expect(histogram_mock).to have_received(:observe).with(
        hash_including(
          rpc_service: 'CellService',
          rpc_method: 'GetCellInfo',
          rpc_status: 'OK'
        ),
        2048
      )
    end

    it 'gracefully handles metric recording failures' do
      histogram_mock = instance_double(Prometheus::Client::Histogram)
      allow(described_class).to receive(:response_size_histogram).and_return(histogram_mock)
      allow(histogram_mock).to receive(:observe).and_raise(StandardError.new('Histogram error'))
      expect(Gitlab::AppLogger).to receive(:debug).with(include('Failed to observe response size'))

      labels = metrics.build_labels(service: 'CellService', method: 'GetCellInfo', status_code: 0)
      expect do
        metrics.observe_response_size(labels: labels, size_bytes: 2048)
      end.not_to raise_error
    end
  end

  describe '#increment_rpc_calls_total' do
    it 'increments RPC calls counter' do
      counter_mock = instance_double(Prometheus::Client::Counter)
      allow(described_class).to receive(:rpc_calls_total_counter).and_return(counter_mock)
      allow(counter_mock).to receive(:increment)

      labels = metrics.build_labels(service: 'CellService', method: 'GetCellInfo', status_code: 0)
      metrics.increment_rpc_calls_total(labels: labels)

      expect(counter_mock).to have_received(:increment).with(
        hash_including(
          rpc_service: 'CellService',
          rpc_method: 'GetCellInfo',
          rpc_status: 'OK'
        )
      )
    end

    it 'gracefully handles metric recording failures' do
      counter_mock = instance_double(Prometheus::Client::Counter)
      allow(described_class).to receive(:rpc_calls_total_counter).and_return(counter_mock)
      allow(counter_mock).to receive(:increment).and_raise(StandardError.new('Counter error'))
      expect(Gitlab::AppLogger).to receive(:debug).with(include('Failed to increment RPC calls total'))

      labels = metrics.build_labels(service: 'CellService', method: 'GetCellInfo', status_code: 0)
      expect do
        metrics.increment_rpc_calls_total(labels: labels)
      end.not_to raise_error
    end
  end

  describe '#increment_failed_calls_total' do
    it 'increments failed calls counter with error type' do
      counter_mock = instance_double(Prometheus::Client::Counter)
      allow(described_class).to receive(:failed_calls_total_counter).and_return(counter_mock)
      allow(counter_mock).to receive(:increment)

      labels = metrics.build_labels(service: 'CellService', method: 'GetCellInfo', status_code: 14)
      metrics.increment_failed_calls_total(labels: labels, error_type: 'unavailable')

      expect(counter_mock).to have_received(:increment).with(
        hash_including(
          rpc_service: 'CellService',
          rpc_method: 'GetCellInfo',
          rpc_status: 'UNAVAILABLE',
          error_type: 'unavailable'
        )
      )
    end

    it 'increments failed calls counter without error type when not provided' do
      counter_mock = instance_double(Prometheus::Client::Counter)
      allow(described_class).to receive(:failed_calls_total_counter).and_return(counter_mock)
      allow(counter_mock).to receive(:increment)

      labels = metrics.build_labels(service: 'CellService', method: 'GetCellInfo', status_code: 14)
      metrics.increment_failed_calls_total(labels: labels)

      expect(counter_mock).to have_received(:increment).with(
        hash_including(
          rpc_service: 'CellService',
          rpc_method: 'GetCellInfo',
          rpc_status: 'UNAVAILABLE'
        )
      )
    end

    it 'does not include error_type in labels when error_type is nil' do
      counter_mock = instance_double(Prometheus::Client::Counter)
      allow(described_class).to receive(:failed_calls_total_counter).and_return(counter_mock)
      allow(counter_mock).to receive(:increment)

      labels = metrics.build_labels(service: 'CellService', method: 'GetCellInfo', status_code: 14)
      metrics.increment_failed_calls_total(labels: labels, error_type: nil)

      expect(counter_mock).to have_received(:increment) do |received_labels|
        expect(received_labels).not_to have_key(:error_type)
        expect(received_labels[:rpc_status]).to eq('UNAVAILABLE')
      end
    end

    it 'gracefully handles metric recording failures' do
      counter_mock = instance_double(Prometheus::Client::Counter)
      allow(described_class).to receive(:failed_calls_total_counter).and_return(counter_mock)
      allow(counter_mock).to receive(:increment).and_raise(StandardError.new('Counter error'))
      expect(Gitlab::AppLogger).to receive(:debug).with(include('Failed to increment failed calls total'))

      labels = metrics.build_labels(service: 'CellService', method: 'GetCellInfo', status_code: 14)
      expect do
        metrics.increment_failed_calls_total(labels: labels, error_type: 'unavailable')
      end.not_to raise_error
    end
  end

  describe '#status_code_to_label' do
    it 'converts gRPC status code to label' do
      expect(metrics.send(:status_code_to_label, 0)).to eq('OK')
      expect(metrics.send(:status_code_to_label, 1)).to eq('CANCELLED')
      expect(metrics.send(:status_code_to_label, 2)).to eq('UNKNOWN')
      expect(metrics.send(:status_code_to_label, 4)).to eq('DEADLINE_EXCEEDED')
      expect(metrics.send(:status_code_to_label, 14)).to eq('UNAVAILABLE')
    end

    it 'returns UNKNOWN for unmapped status codes' do
      expect(metrics.send(:status_code_to_label, 999)).to eq('UNKNOWN')
    end

    it 'gracefully handles errors during conversion' do
      expect(metrics.send(:status_code_to_label, nil)).to eq('UNKNOWN')
    end
  end

  describe '.metric' do
    context 'with histogram type' do
      it 'creates histogram metric with correct parameters' do
        histogram_mock = instance_double(Prometheus::Client::Histogram)
        expect(::Gitlab::Metrics).to receive(:histogram).with(
          :test_histogram,
          'Test histogram metric',
          hash_including(
            rpc_service: nil,
            rpc_method: nil,
            rpc_status: nil,
            rpc_system: 'grpc',
            cell_id: nil,
            topology_service_address: nil,
            custom_label: 'custom_value'
          ),
          [0.1, 0.5, 1.0]
        ).and_return(histogram_mock)

        result = described_class.metric(:test_histogram, 'Test histogram metric',
          type: :histogram,
          buckets: [0.1, 0.5, 1.0],
          extra_labels: { custom_label: 'custom_value' })
        expect(result).to eq(histogram_mock)
      end
    end

    context 'with counter type' do
      it 'creates counter metric with correct parameters' do
        counter_mock = instance_double(Prometheus::Client::Counter)
        expect(::Gitlab::Metrics).to receive(:counter).with(
          :test_counter,
          'Test counter metric',
          hash_including(
            rpc_service: nil,
            rpc_method: nil,
            rpc_status: nil,
            rpc_system: 'grpc',
            cell_id: nil,
            topology_service_address: nil,
            custom_label: 'custom_value'
          )
        ).and_return(counter_mock)

        result = described_class.metric(:test_counter, 'Test counter metric',
          type: :counter,
          extra_labels: { custom_label: 'custom_value' })
        expect(result).to eq(counter_mock)
      end
    end

    context 'with unsupported type' do
      it 'raises ArgumentError for unsupported metric type' do
        expect do
          described_class.metric(:invalid_metric, 'Invalid metric', type: :gauge)
        end.to raise_error(ArgumentError, 'Unsupported metric type: gauge')
      end

      it 'raises ArgumentError for nil type' do
        expect do
          described_class.metric(:invalid_metric, 'Invalid metric', type: nil)
        end.to raise_error(ArgumentError, 'Unsupported metric type: ')
      end

      it 'raises ArgumentError for unknown type' do
        expect do
          described_class.metric(:invalid_metric, 'Invalid metric', type: :unknown)
        end.to raise_error(ArgumentError, 'Unsupported metric type: unknown')
      end
    end

    context 'with default parameters' do
      it 'uses default empty buckets and extra_labels' do
        histogram_mock = instance_double(Prometheus::Client::Histogram)
        expect(::Gitlab::Metrics).to receive(:histogram).with(
          :default_metric,
          'Default metric',
          hash_including(rpc_system: 'grpc'),
          nil
        ).and_return(histogram_mock)

        result = described_class.metric(:default_metric, 'Default metric', type: :histogram)
        expect(result).to eq(histogram_mock)
      end
    end
  end

  describe 'metric definitions' do
    describe '.rpc_duration_histogram' do
      it 'creates histogram with correct parameters' do
        histogram_mock = instance_double(Prometheus::Client::Histogram)
        expect(::Gitlab::Metrics).to receive(:histogram).with(
          :topology_service_rpc_duration_seconds,
          'RPC call duration in seconds',
          hash_including(
            rpc_service: nil,
            rpc_method: nil,
            rpc_status: nil,
            rpc_system: 'grpc',
            cell_id: nil,
            topology_service_address: nil
          ),
          described_class::DURATION_BUCKETS
        ).and_return(histogram_mock)

        result = described_class.rpc_duration_histogram
        expect(result).to eq(histogram_mock)
      end

      it 'memoizes the histogram' do
        # Allow the first call to go through
        allow(::Gitlab::Metrics).to receive(:histogram).and_return(instance_double(Prometheus::Client::Histogram))

        histogram1 = described_class.rpc_duration_histogram
        histogram2 = described_class.rpc_duration_histogram

        expect(histogram1).to be(histogram2)
      end
    end

    describe '.request_size_histogram' do
      it 'creates histogram with correct parameters' do
        histogram_mock = instance_double(Prometheus::Client::Histogram)
        expect(::Gitlab::Metrics).to receive(:histogram).with(
          :topology_service_rpc_request_size_bytes,
          'RPC request size in bytes',
          hash_including(rpc_system: 'grpc'),
          described_class::SIZE_BUCKETS
        ).and_return(histogram_mock)

        result = described_class.request_size_histogram
        expect(result).to eq(histogram_mock)
      end
    end

    describe '.response_size_histogram' do
      it 'creates histogram with correct parameters' do
        histogram_mock = instance_double(Prometheus::Client::Histogram)
        expect(::Gitlab::Metrics).to receive(:histogram).with(
          :topology_service_rpc_response_size_bytes,
          'RPC response size in bytes',
          hash_including(rpc_system: 'grpc'),
          described_class::SIZE_BUCKETS
        ).and_return(histogram_mock)

        result = described_class.response_size_histogram
        expect(result).to eq(histogram_mock)
      end
    end

    describe '.rpc_calls_total_counter' do
      it 'creates counter with correct parameters' do
        counter_mock = instance_double(Prometheus::Client::Counter)
        expect(::Gitlab::Metrics).to receive(:counter).with(
          :topology_service_rpc_calls_total,
          'Total number of RPC calls',
          hash_including(rpc_system: 'grpc')
        ).and_return(counter_mock)

        result = described_class.rpc_calls_total_counter

        expect(result).to eq(counter_mock)
      end
    end

    describe '.failed_calls_total_counter' do
      it 'creates counter with correct parameters' do
        counter_mock = instance_double(Prometheus::Client::Counter)
        expect(::Gitlab::Metrics).to receive(:counter).with(
          :topology_service_rpc_failed_calls_total,
          'Total number of failed RPC calls',
          hash_including(rpc_system: 'grpc')
        ).and_return(counter_mock)

        result = described_class.failed_calls_total_counter
        expect(result).to eq(counter_mock)
      end
    end
  end

  describe 'constant definitions' do
    it 'defines DURATION_BUCKETS with appropriate values for latency' do
      # Use milliseconds range to avoid floating point conversion issues
      # Expected values: 1ms, 10ms, 100ms, 1000ms
      expect(described_class::DURATION_BUCKETS).to include(
        1.0 / 1000,   # 1ms
        10.0 / 1000,  # 10ms
        100.0 / 1000, # 100ms
        1.0           # 1000ms
      )
      expect(described_class::DURATION_BUCKETS).to be_frozen
    end

    it 'defines SIZE_BUCKETS with exponential values' do
      expect(described_class::SIZE_BUCKETS).to include(100, 1000, 10000, 100000, 1000000)
      expect(described_class::SIZE_BUCKETS).to be_frozen
    end
  end
end
