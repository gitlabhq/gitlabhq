# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Topology Service Metrics Integration', feature_category: :cell do
  let(:cell_id) { '1' }
  let(:topology_service_address) { 'localhost:50051' }

  before do
    stub_config_cell({
      enabled: true,
      id: cell_id,
      topology_service_client: {
        address: topology_service_address,
        tls: { enabled: false },
        metadata: {}
      }
    })
  end

  describe 'BaseService metrics interceptor integration' do
    let(:base_service) { Gitlab::TopologyServiceClient::BaseService.new }

    context 'when metrics are enabled' do
      before do
        allow(::Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(true)
      end

      it 'includes MetricsInterceptor in the interceptors list' do
        interceptors = base_service.send(:build_interceptors)

        expect(interceptors).to include(instance_of(Gitlab::TopologyServiceClient::MetricsInterceptor))
      end

      it 'passes cell_id and topology_service_address to MetricsInterceptor' do
        expect(Gitlab::TopologyServiceClient::MetricsInterceptor).to receive(:new).with(
          cell_id: cell_id,
          topology_service_address: topology_service_address
        ).and_call_original

        base_service.send(:build_interceptors)
      end

      it 'includes other required interceptors alongside MetricsInterceptor' do
        interceptors = base_service.send(:build_interceptors)

        expect(interceptors).to include(instance_of(Labkit::Correlation::GRPC::ClientInterceptor))
        expect(interceptors).to include(instance_of(Gitlab::Cells::TopologyService::MetadataClient))
        expect(interceptors).to include(instance_of(Gitlab::TopologyServiceClient::MetricsInterceptor))
      end
    end

    context 'when metrics are disabled' do
      before do
        allow(::Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(false)
      end

      it 'does not include MetricsInterceptor in the interceptors list' do
        interceptors = base_service.send(:build_interceptors)

        expect(interceptors).not_to include(instance_of(Gitlab::TopologyServiceClient::MetricsInterceptor))
      end

      it 'still includes other required interceptors' do
        interceptors = base_service.send(:build_interceptors)

        expect(interceptors).to include(instance_of(Labkit::Correlation::GRPC::ClientInterceptor))
        expect(interceptors).to include(instance_of(Gitlab::Cells::TopologyService::MetadataClient))
      end
    end

    it 'maintains backward compatibility with existing interceptor order' do
      allow(::Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(false)
      interceptors = base_service.send(:build_interceptors)

      # Ensure order is: Correlation -> Metadata -> [Metrics if enabled]
      expect(interceptors[0]).to be_instance_of(Labkit::Correlation::GRPC::ClientInterceptor)
      expect(interceptors[1]).to be_instance_of(Gitlab::Cells::TopologyService::MetadataClient)
    end
  end

  describe 'Metrics recording in realistic scenarios' do
    let(:metrics) do
      Gitlab::TopologyServiceClient::Metrics.new(cell_id: cell_id, topology_service_address: topology_service_address)
    end

    before do
      allow(::Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(true)
    end

    describe 'error classification' do
      let(:interceptor) do
        Gitlab::TopologyServiceClient::MetricsInterceptor.new(cell_id: cell_id,
          topology_service_address: topology_service_address)
      end

      it 'classifies various error types correctly' do
        errors = {
          GRPC::BadStatus.new(GRPC::Core::StatusCodes::DEADLINE_EXCEEDED, 'Timeout') => 'timeout',
          GRPC::BadStatus.new(GRPC::Core::StatusCodes::UNAVAILABLE, 'Unavailable') => 'unavailable',
          Errno::ECONNREFUSED.new => 'network_error',
          Timeout::Error.new => 'timeout',
          RuntimeError.new => 'unknown_error'
        }

        errors.each do |error, expected_classification|
          classification = interceptor.send(:classify_error, error)
          expect(classification).to eq(expected_classification)
        end
      end
    end

    describe 'label building' do
      it 'builds labels with all required fields' do
        labels = metrics.send(:build_labels, service: 'CellService', method: 'GetCellInfo', status_code: 0)

        expect(labels).to include(
          rpc_service: 'CellService',
          rpc_method: 'GetCellInfo',
          rpc_status: 'OK',
          rpc_system: 'grpc',
          cell_id: cell_id,
          topology_service_address: topology_service_address
        )
      end

      it 'consistently builds labels across multiple calls' do
        labels1 = metrics.send(:build_labels, service: 'CellService', method: 'GetCellInfo', status_code: 0)
        labels2 = metrics.send(:build_labels, service: 'CellService', method: 'GetCellInfo', status_code: 0)

        expect(labels1).to eq(labels2)
      end
    end
  end

  describe 'metric constants' do
    it 'exposes DURATION_BUCKETS with appropriate latency boundaries' do
      buckets = Gitlab::TopologyServiceClient::Metrics::DURATION_BUCKETS
      # Convert to milliseconds for integer-based comparison to avoid floating point precision issues
      buckets_ms = buckets.map { |b| (b * 1000).round }

      # Verify coverage for SLOs: 1ms, 5ms, 10ms, 25ms, 50ms, 100ms, 250ms, 500ms, 1s, 2.5s, 5s
      expect(buckets_ms).to include(1, 10, 100, 1000, 5000)
    end

    it 'exposes SIZE_BUCKETS with exponential distribution' do
      buckets = Gitlab::TopologyServiceClient::Metrics::SIZE_BUCKETS

      # Verify exponential scale for byte sizes
      expect(buckets).to include(100, 1000, 10000, 100000, 1000000)
    end
  end

  describe 'performance considerations' do
    let(:metrics) do
      Gitlab::TopologyServiceClient::Metrics.new(cell_id: cell_id, topology_service_address: topology_service_address)
    end

    let(:interceptor) do
      Gitlab::TopologyServiceClient::MetricsInterceptor.new(cell_id: cell_id,
        topology_service_address: topology_service_address)
    end

    before do
      allow(::Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(true)
    end

    it 'memoizes metric definitions for efficiency' do
      histogram1 = Gitlab::TopologyServiceClient::Metrics.rpc_duration_histogram
      histogram2 = Gitlab::TopologyServiceClient::Metrics.rpc_duration_histogram

      expect(histogram1).to be(histogram2)
    end

    it 'gracefully handles metric recording errors without blocking RPC calls' do
      histogram_mock = instance_double(Prometheus::Client::Histogram)
      allow(Gitlab::TopologyServiceClient::Metrics).to receive(:rpc_duration_histogram).and_return(histogram_mock)
      allow(histogram_mock).to receive(:observe).and_raise(StandardError.new('Metric error'))
      expect(Gitlab::AppLogger).to receive(:debug)

      # Should not raise, metrics recording failure should not block the call
      # Use milliseconds converted to seconds to ensure precise floating point value
      duration_ms = 500
      duration_seconds = duration_ms / 1000.0

      expect do
        labels = metrics.build_labels(service: 'CellService', method: 'GetCellInfo', status_code: 0)
        metrics.observe_rpc_duration(labels: labels, duration_seconds: duration_seconds)
      end.not_to raise_error
    end

    it 'uses monotonic_time for accurate duration measurement' do
      expect(Gitlab::Metrics::System).to receive(:monotonic_time).at_least(:once)

      interceptor.send(:monotonic_time)
    end
  end

  describe 'security and privacy' do
    let(:metrics) do
      Gitlab::TopologyServiceClient::Metrics.new(cell_id: cell_id, topology_service_address: topology_service_address)
    end

    it 'does not record sensitive request/response payloads' do
      # Verify that only sizes are recorded, not actual payload content
      labels = metrics.send(:build_labels, service: 'CellService', method: 'GetCellInfo', status_code: 0)

      expect(labels.keys).not_to include(:request_payload, :response_payload, :message_content)
    end

    it 'records non-sensitive cell_id and service names' do
      labels = metrics.send(:build_labels, service: 'CellService', method: 'GetCellInfo', status_code: 0)

      # These are appropriate to record as they're non-sensitive identifiers
      expect(labels).to include(
        cell_id: cell_id,
        rpc_service: 'CellService'
      )
    end
  end
end
