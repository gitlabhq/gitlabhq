# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::MetricsInterceptor, feature_category: :cell do
  let(:cell_id) { '1' }
  let(:topology_service_address) { 'localhost:50051' }
  let(:interceptor) { described_class.new(cell_id: cell_id, topology_service_address: topology_service_address) }
  let(:call) { double('call') } # rubocop:disable RSpec/VerifiedDoubles -- No concrete class available for gRPC call
  let(:metadata) { {} }

  before do
    allow(::Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(true)
  end

  after do
    # Clear all memoization after each test to prevent mocks from leaking to subsequent tests
    Gitlab::TopologyServiceClient::Metrics.clear_memoization(:rpc_duration_histogram)
    Gitlab::TopologyServiceClient::Metrics.clear_memoization(:request_size_histogram)
    Gitlab::TopologyServiceClient::Metrics.clear_memoization(:response_size_histogram)
    Gitlab::TopologyServiceClient::Metrics.clear_memoization(:rpc_calls_total_counter)
    Gitlab::TopologyServiceClient::Metrics.clear_memoization(:failed_calls_total_counter)
  end

  describe '#request_response' do
    let(:method) { '/proto.CellService/GetCellInfo' }
    let(:request) { double('request') } # rubocop:disable RSpec/VerifiedDoubles -- No concrete class available for gRPC request
    let(:response) { double('response') } # rubocop:disable RSpec/VerifiedDoubles -- No concrete class available for gRPC response

    before do
      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(1.0, 1.5)
    end

    it 'records metrics on successful RPC call' do
      metrics = instance_double(Gitlab::TopologyServiceClient::Metrics)
      labels = {
        rpc_service: 'proto.CellService',
        rpc_method: 'GetCellInfo',
        rpc_status: 'OK',
        rpc_system: 'grpc',
        cell_id: cell_id,
        topology_service_address: topology_service_address
      }

      allow(Gitlab::TopologyServiceClient::Metrics).to receive(:new).and_return(metrics)
      allow(metrics).to receive(:build_labels).and_return(labels)
      allow(metrics).to receive(:increment_rpc_calls_total)
      allow(metrics).to receive(:observe_rpc_duration)

      interceptor.request_response(request: request, call: call, method: method, metadata: metadata) { response }

      expect(metrics).to have_received(:build_labels).with(
        service: 'proto.CellService',
        method: 'GetCellInfo',
        status_code: GRPC::Core::StatusCodes::OK
      )
      expect(metrics).to have_received(:increment_rpc_calls_total).with(labels: labels)
      expect(metrics).to have_received(:observe_rpc_duration).with(
        labels: labels,
        duration_seconds: 0.5
      )
    end

    it 'records metrics on gRPC error' do
      metrics = instance_double(Gitlab::TopologyServiceClient::Metrics)
      labels = {
        rpc_service: 'proto.CellService',
        rpc_method: 'GetCellInfo',
        rpc_status: 'UNAVAILABLE',
        rpc_system: 'grpc',
        cell_id: cell_id,
        topology_service_address: topology_service_address
      }

      allow(Gitlab::TopologyServiceClient::Metrics).to receive(:new).and_return(metrics)
      allow(metrics).to receive(:build_labels).and_return(labels)
      allow(metrics).to receive(:increment_rpc_calls_total)
      allow(metrics).to receive(:observe_rpc_duration)
      allow(metrics).to receive(:increment_failed_calls_total)

      error = GRPC::BadStatus.new(GRPC::Core::StatusCodes::UNAVAILABLE, 'Service unavailable')

      expect do
        interceptor.request_response(request: request, call: call, method: method, metadata: metadata) { raise error }
      end.to raise_error(GRPC::BadStatus)

      expect(metrics).to have_received(:build_labels).with(
        service: 'proto.CellService',
        method: 'GetCellInfo',
        status_code: GRPC::Core::StatusCodes::UNAVAILABLE
      )
      expect(metrics).to have_received(:increment_failed_calls_total).with(
        labels: labels,
        error_type: 'unavailable'
      )
    end

    it 'records metrics on unexpected error' do
      metrics = instance_double(Gitlab::TopologyServiceClient::Metrics)
      labels = {
        rpc_service: 'proto.CellService',
        rpc_method: 'GetCellInfo',
        rpc_status: 'UNKNOWN',
        rpc_system: 'grpc',
        cell_id: cell_id,
        topology_service_address: topology_service_address
      }

      allow(Gitlab::TopologyServiceClient::Metrics).to receive(:new).and_return(metrics)
      allow(metrics).to receive(:build_labels).and_return(labels)
      allow(metrics).to receive(:increment_rpc_calls_total)
      allow(metrics).to receive(:observe_rpc_duration)
      allow(metrics).to receive(:increment_failed_calls_total)

      error = RuntimeError.new('Unexpected error')

      expect do
        interceptor.request_response(request: request, call: call, method: method, metadata: metadata) { raise error }
      end.to raise_error(RuntimeError)

      expect(metrics).to have_received(:build_labels).with(
        service: 'proto.CellService',
        method: 'GetCellInfo',
        status_code: GRPC::Core::StatusCodes::UNKNOWN
      )
      expect(metrics).to have_received(:increment_failed_calls_total).with(
        labels: labels,
        error_type: 'unknown_error'
      )
    end

    it 'does not record metrics when prometheus metrics are disabled' do
      # Clear any memoized metrics from previous tests to avoid mock leakage
      Gitlab::TopologyServiceClient::Metrics.clear_memoization(:rpc_duration_histogram)
      Gitlab::TopologyServiceClient::Metrics.clear_memoization(:request_size_histogram)
      Gitlab::TopologyServiceClient::Metrics.clear_memoization(:response_size_histogram)
      Gitlab::TopologyServiceClient::Metrics.clear_memoization(:rpc_calls_total_counter)
      Gitlab::TopologyServiceClient::Metrics.clear_memoization(:failed_calls_total_counter)

      # When prometheus is disabled, Gitlab::Metrics returns NullMetric which accepts all calls but does nothing
      # We verify this by stubbing histogram/counter to return NullMetric and checking it receives the calls
      null_metric = Gitlab::Metrics::NullMetric.instance

      allow(::Gitlab::Metrics).to receive_messages(prometheus_metrics_enabled?: false, histogram: null_metric,
        counter: null_metric)

      result = interceptor.request_response(request: request, call: call, method: method, metadata: metadata) do
        response
      end

      # Verify the call completes successfully
      expect(result).to eq(response)

      # Verify that Gitlab::Metrics was called to create metrics (but returned NullMetric)
      expect(::Gitlab::Metrics).to have_received(:histogram).with(
        :topology_service_rpc_duration_seconds,
        'RPC call duration in seconds',
        hash_including(rpc_service: nil, rpc_method: nil),
        Gitlab::TopologyServiceClient::Metrics::DURATION_BUCKETS
      )
      expect(::Gitlab::Metrics).to have_received(:counter).with(
        :topology_service_rpc_calls_total,
        'Total number of RPC calls',
        hash_including(rpc_service: nil, rpc_method: nil)
      )
    end
  end

  describe '#extract_service_and_method' do
    it 'correctly extracts service and method name' do
      service, method = interceptor.send(:extract_service_and_method, '/proto.CellService/GetCellInfo')

      expect(service).to eq('proto.CellService')
      expect(method).to eq('GetCellInfo')
    end

    it 'returns unknown when method format is invalid' do
      service, method = interceptor.send(:extract_service_and_method, 'invalid')

      expect(service).to eq('unknown')
      expect(method).to eq('unknown')
    end
  end

  describe '#estimate_message_size' do
    it 'returns bytesize for string messages' do
      message = 'test message'
      size = interceptor.send(:estimate_message_size, message)

      expect(size).to eq(message.bytesize)
    end

    it 'returns 0 for nil messages' do
      size = interceptor.send(:estimate_message_size, nil)

      expect(size).to eq(0)
    end

    it 'handles protobuf messages with to_proto method' do
      message = double('message') # rubocop:disable RSpec/VerifiedDoubles -- Generic message object for testing
      proto = double('proto') # rubocop:disable RSpec/VerifiedDoubles -- Generic proto object for testing

      allow(message).to receive(:respond_to?).with(:to_proto).and_return(true)
      allow(message).to receive(:to_proto).and_return(proto)
      allow(proto).to receive(:bytesize).and_return(42)

      size = interceptor.send(:estimate_message_size, message)

      expect(size).to eq(42)
    end

    it 'gracefully handles estimation errors' do
      message = double('message') # rubocop:disable RSpec/VerifiedDoubles -- Generic message object for testing
      allow(message).to receive_messages(respond_to?: false, is_a?: false)

      size = interceptor.send(:estimate_message_size, message)

      expect(size).to eq(0)
    end
  end

  describe '#classify_error' do
    it 'classifies DEADLINE_EXCEEDED as timeout' do
      error = GRPC::BadStatus.new(GRPC::Core::StatusCodes::DEADLINE_EXCEEDED, 'Deadline exceeded')
      classification = interceptor.send(:classify_error, error)

      expect(classification).to eq('timeout')
    end

    it 'classifies UNAVAILABLE as unavailable' do
      error = GRPC::BadStatus.new(GRPC::Core::StatusCodes::UNAVAILABLE, 'Service unavailable')
      classification = interceptor.send(:classify_error, error)

      expect(classification).to eq('unavailable')
    end

    it 'classifies PERMISSION_DENIED as permission_denied' do
      error = GRPC::BadStatus.new(GRPC::Core::StatusCodes::PERMISSION_DENIED, 'Permission denied')
      classification = interceptor.send(:classify_error, error)

      expect(classification).to eq('permission_denied')
    end

    it 'classifies INVALID_ARGUMENT as invalid_argument' do
      error = GRPC::BadStatus.new(GRPC::Core::StatusCodes::INVALID_ARGUMENT, 'Invalid argument')
      classification = interceptor.send(:classify_error, error)

      expect(classification).to eq('invalid_argument')
    end

    it 'classifies NOT_FOUND as not_found' do
      error = GRPC::BadStatus.new(GRPC::Core::StatusCodes::NOT_FOUND, 'Not found')
      classification = interceptor.send(:classify_error, error)

      expect(classification).to eq('not_found')
    end

    it 'classifies RESOURCE_EXHAUSTED as resource_exhausted' do
      error = GRPC::BadStatus.new(GRPC::Core::StatusCodes::RESOURCE_EXHAUSTED, 'Resource exhausted')
      classification = interceptor.send(:classify_error, error)

      expect(classification).to eq('resource_exhausted')
    end

    it 'classifies CANCELLED as cancelled' do
      error = GRPC::BadStatus.new(GRPC::Core::StatusCodes::CANCELLED, 'Cancelled')
      classification = interceptor.send(:classify_error, error)

      expect(classification).to eq('cancelled')
    end

    it 'classifies network errors' do
      error = Errno::ECONNREFUSED.new
      classification = interceptor.send(:classify_error, error)

      expect(classification).to eq('network_error')
    end

    it 'classifies timeout errors' do
      error = Timeout::Error.new
      classification = interceptor.send(:classify_error, error)

      expect(classification).to eq('timeout')
    end

    it 'classifies unknown errors' do
      error = RuntimeError.new('Unknown error')
      classification = interceptor.send(:classify_error, error)

      expect(classification).to eq('unknown_error')
    end
  end

  describe '#monotonic_time' do
    it 'returns monotonic time from Gitlab::Metrics::System' do
      expect(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(42.0)

      time = interceptor.send(:monotonic_time)

      expect(time).to eq(42.0)
    end
  end

  describe '#client_streaming' do
    let(:method) { '/proto.CellService/UploadData' }
    let(:requests) { [double('request1'), double('request2')] } # rubocop:disable RSpec/VerifiedDoubles -- No concrete class available
    let(:response) { double('response') } # rubocop:disable RSpec/VerifiedDoubles -- No concrete class available

    before do
      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(1.0, 1.5)
    end

    it 'records metrics on successful RPC call' do
      metrics = instance_double(Gitlab::TopologyServiceClient::Metrics)
      labels = {
        rpc_service: 'proto.CellService',
        rpc_method: 'UploadData',
        rpc_status: 'OK',
        rpc_system: 'grpc',
        cell_id: cell_id,
        topology_service_address: topology_service_address
      }

      allow(Gitlab::TopologyServiceClient::Metrics).to receive(:new).and_return(metrics)
      allow(metrics).to receive(:build_labels).and_return(labels)
      allow(metrics).to receive(:increment_rpc_calls_total)
      allow(metrics).to receive(:observe_rpc_duration)
      allow(metrics).to receive(:observe_request_size)
      allow(metrics).to receive(:observe_response_size)

      result = interceptor.client_streaming(requests: requests, call: call, method: method,
        metadata: metadata) do |enum|
        enum.to_a # Consume the wrapped requests
        response
      end

      expect(result).to eq(response)
      expect(metrics).to have_received(:build_labels).with(
        service: 'proto.CellService',
        method: 'UploadData',
        status_code: GRPC::Core::StatusCodes::OK
      )
      expect(metrics).to have_received(:increment_rpc_calls_total).with(labels: labels)
      expect(metrics).to have_received(:observe_rpc_duration).with(
        labels: labels,
        duration_seconds: 0.5
      )
    end

    it 'records metrics on gRPC error' do
      metrics = instance_double(Gitlab::TopologyServiceClient::Metrics)
      labels = {
        rpc_service: 'proto.CellService',
        rpc_method: 'UploadData',
        rpc_status: 'UNAVAILABLE',
        rpc_system: 'grpc',
        cell_id: cell_id,
        topology_service_address: topology_service_address
      }

      allow(Gitlab::TopologyServiceClient::Metrics).to receive(:new).and_return(metrics)
      allow(metrics).to receive(:build_labels).and_return(labels)
      allow(metrics).to receive(:increment_rpc_calls_total)
      allow(metrics).to receive(:observe_rpc_duration)
      allow(metrics).to receive(:increment_failed_calls_total)

      error = GRPC::BadStatus.new(GRPC::Core::StatusCodes::UNAVAILABLE, 'Service unavailable')

      expect do
        interceptor.client_streaming(requests: requests, call: call, method: method, metadata: metadata) do
          raise error
        end
      end.to raise_error(GRPC::BadStatus)

      expect(metrics).to have_received(:increment_failed_calls_total).with(
        labels: labels,
        error_type: 'unavailable'
      )
    end

    it 'records metrics on unexpected error' do
      metrics = instance_double(Gitlab::TopologyServiceClient::Metrics)
      labels = {
        rpc_service: 'proto.CellService',
        rpc_method: 'UploadData',
        rpc_status: 'UNKNOWN',
        rpc_system: 'grpc',
        cell_id: cell_id,
        topology_service_address: topology_service_address
      }

      allow(Gitlab::TopologyServiceClient::Metrics).to receive(:new).and_return(metrics)
      allow(metrics).to receive(:build_labels).and_return(labels)
      allow(metrics).to receive(:increment_rpc_calls_total)
      allow(metrics).to receive(:observe_rpc_duration)
      allow(metrics).to receive(:increment_failed_calls_total)

      error = RuntimeError.new('Unexpected error')

      expect do
        interceptor.client_streaming(requests: requests, call: call, method: method, metadata: metadata) do
          raise error
        end
      end.to raise_error(RuntimeError)

      expect(metrics).to have_received(:increment_failed_calls_total).with(
        labels: labels,
        error_type: 'unknown_error'
      )
    end
  end

  describe '#server_streaming' do
    let(:method) { '/proto.CellService/StreamData' }
    let(:request) { double('request') } # rubocop:disable RSpec/VerifiedDoubles -- No concrete class available
    let(:responses) { [double('response1'), double('response2'), double('response3')] } # rubocop:disable RSpec/VerifiedDoubles -- No concrete class available

    before do
      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(1.0, 1.5)
    end

    it 'records metrics on successful RPC call' do
      metrics = instance_double(Gitlab::TopologyServiceClient::Metrics)
      labels = {
        rpc_service: 'proto.CellService',
        rpc_method: 'StreamData',
        rpc_status: 'OK',
        rpc_system: 'grpc',
        cell_id: cell_id,
        topology_service_address: topology_service_address
      }

      allow(Gitlab::TopologyServiceClient::Metrics).to receive(:new).and_return(metrics)
      allow(metrics).to receive(:build_labels).and_return(labels)
      allow(metrics).to receive(:increment_rpc_calls_total)
      allow(metrics).to receive(:observe_rpc_duration)
      allow(metrics).to receive(:observe_request_size)
      allow(metrics).to receive(:observe_response_size)

      # The method yields responses_enum and we need to consume it
      result_enum = interceptor.server_streaming(request: request, call: call, method: method, metadata: metadata) do
        responses.to_enum
      end
      result_enum.to_a # Consume the enumerator to trigger metrics recording

      expect(metrics).to have_received(:build_labels).with(
        service: 'proto.CellService',
        method: 'StreamData',
        status_code: GRPC::Core::StatusCodes::OK
      )
      expect(metrics).to have_received(:increment_rpc_calls_total).with(labels: labels)
      expect(metrics).to have_received(:observe_rpc_duration).with(
        labels: labels,
        duration_seconds: within(0.001).of(0.5)
      )
    end

    it 'records metrics on gRPC error' do
      metrics = instance_double(Gitlab::TopologyServiceClient::Metrics)
      labels = {
        rpc_service: 'proto.CellService',
        rpc_method: 'StreamData',
        rpc_status: 'UNAVAILABLE',
        rpc_system: 'grpc',
        cell_id: cell_id,
        topology_service_address: topology_service_address
      }

      allow(Gitlab::TopologyServiceClient::Metrics).to receive(:new).and_return(metrics)
      allow(metrics).to receive(:build_labels).and_return(labels)
      allow(metrics).to receive(:increment_rpc_calls_total)
      allow(metrics).to receive(:observe_rpc_duration)
      allow(metrics).to receive(:increment_failed_calls_total)

      error = GRPC::BadStatus.new(GRPC::Core::StatusCodes::UNAVAILABLE, 'Service unavailable')

      expect do
        interceptor.server_streaming(request: request, call: call, method: method, metadata: metadata) { raise error }
      end.to raise_error(GRPC::BadStatus)

      expect(metrics).to have_received(:increment_failed_calls_total).with(
        labels: labels,
        error_type: 'unavailable'
      )
    end

    it 'records metrics on unexpected error' do
      metrics = instance_double(Gitlab::TopologyServiceClient::Metrics)
      labels = {
        rpc_service: 'proto.CellService',
        rpc_method: 'StreamData',
        rpc_status: 'UNKNOWN',
        rpc_system: 'grpc',
        cell_id: cell_id,
        topology_service_address: topology_service_address
      }

      allow(Gitlab::TopologyServiceClient::Metrics).to receive(:new).and_return(metrics)
      allow(metrics).to receive(:build_labels).and_return(labels)
      allow(metrics).to receive(:increment_rpc_calls_total)
      allow(metrics).to receive(:observe_rpc_duration)
      allow(metrics).to receive(:increment_failed_calls_total)

      error = RuntimeError.new('Unexpected error')

      expect do
        interceptor.server_streaming(request: request, call: call, method: method, metadata: metadata) { raise error }
      end.to raise_error(RuntimeError)

      expect(metrics).to have_received(:increment_failed_calls_total).with(
        labels: labels,
        error_type: 'unknown_error'
      )
    end
  end

  describe '#bidi_streamer' do
    let(:method) { '/proto.CellService/BidirectionalStream' }
    let(:requests) { [double('request1'), double('request2')] } # rubocop:disable RSpec/VerifiedDoubles -- No concrete class available
    let(:responses) { [double('response1'), double('response2')] } # rubocop:disable RSpec/VerifiedDoubles -- No concrete class available

    before do
      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(1.0, 1.5)
    end

    it 'records metrics on successful RPC call' do
      metrics = instance_double(Gitlab::TopologyServiceClient::Metrics)
      labels = {
        rpc_service: 'proto.CellService',
        rpc_method: 'BidirectionalStream',
        rpc_status: 'OK',
        rpc_system: 'grpc',
        cell_id: cell_id,
        topology_service_address: topology_service_address
      }

      allow(Gitlab::TopologyServiceClient::Metrics).to receive(:new).and_return(metrics)
      allow(metrics).to receive(:build_labels).and_return(labels)
      allow(metrics).to receive(:increment_rpc_calls_total)
      allow(metrics).to receive(:observe_rpc_duration)

      result_enum = interceptor.bidi_streamer(requests: requests, call: call, method: method,
        metadata: metadata) do |req_enum|
        req_enum.to_a # Consume the wrapped requests
        responses.to_enum
      end

      # Consume the response enumerator to trigger metric recording
      result_enum.to_a

      expect(metrics).to have_received(:build_labels).with(
        service: 'proto.CellService',
        method: 'BidirectionalStream',
        status_code: GRPC::Core::StatusCodes::OK
      )
      expect(metrics).to have_received(:increment_rpc_calls_total).with(labels: labels)
      expect(metrics).to have_received(:observe_rpc_duration).with(
        labels: labels,
        duration_seconds: within(0.001).of(0.5)
      )
    end

    it 'records metrics on gRPC error' do
      metrics = instance_double(Gitlab::TopologyServiceClient::Metrics)
      labels = {
        rpc_service: 'proto.CellService',
        rpc_method: 'BidirectionalStream',
        rpc_status: 'UNAVAILABLE',
        rpc_system: 'grpc',
        cell_id: cell_id,
        topology_service_address: topology_service_address
      }

      allow(Gitlab::TopologyServiceClient::Metrics).to receive(:new).and_return(metrics)
      allow(metrics).to receive(:build_labels).and_return(labels)
      allow(metrics).to receive(:increment_rpc_calls_total)
      allow(metrics).to receive(:observe_rpc_duration)
      allow(metrics).to receive(:increment_failed_calls_total)

      error = GRPC::BadStatus.new(GRPC::Core::StatusCodes::UNAVAILABLE, 'Service unavailable')

      expect do
        interceptor.bidi_streamer(requests: requests, call: call, method: method, metadata: metadata) { raise error }
      end.to raise_error(GRPC::BadStatus)

      expect(metrics).to have_received(:increment_failed_calls_total).with(
        labels: labels,
        error_type: 'unavailable'
      )
    end

    it 'records metrics on unexpected error' do
      metrics = instance_double(Gitlab::TopologyServiceClient::Metrics)
      labels = {
        rpc_service: 'proto.CellService',
        rpc_method: 'BidirectionalStream',
        rpc_status: 'UNKNOWN',
        rpc_system: 'grpc',
        cell_id: cell_id,
        topology_service_address: topology_service_address
      }

      allow(Gitlab::TopologyServiceClient::Metrics).to receive(:new).and_return(metrics)
      allow(metrics).to receive(:build_labels).and_return(labels)
      allow(metrics).to receive(:increment_rpc_calls_total)
      allow(metrics).to receive(:observe_rpc_duration)
      allow(metrics).to receive(:increment_failed_calls_total)

      error = RuntimeError.new('Unexpected error')

      expect do
        interceptor.bidi_streamer(requests: requests, call: call, method: method, metadata: metadata) { raise error }
      end.to raise_error(RuntimeError)

      expect(metrics).to have_received(:increment_failed_calls_total).with(
        labels: labels,
        error_type: 'unknown_error'
      )
    end
  end

  describe 'request and response size tracking' do
    let(:method) { '/proto.CellService/GetCellInfo' }

    before do
      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(1.0, 1.5)
    end

    context 'with protobuf messages' do
      it 'records request and response sizes' do
        request = double('request') # rubocop:disable RSpec/VerifiedDoubles -- Generic test double
        response = double('response') # rubocop:disable RSpec/VerifiedDoubles -- Generic test double
        request_proto = double('request_proto', bytesize: 100) # rubocop:disable RSpec/VerifiedDoubles -- Generic test double
        response_proto = double('response_proto', bytesize: 200) # rubocop:disable RSpec/VerifiedDoubles -- Generic test double

        allow(request).to receive(:respond_to?).with(:to_proto).and_return(true)
        allow(request).to receive(:to_proto).and_return(request_proto)
        allow(response).to receive(:respond_to?).with(:to_proto).and_return(true)
        allow(response).to receive(:to_proto).and_return(response_proto)

        metrics = instance_double(Gitlab::TopologyServiceClient::Metrics)
        labels = { rpc_service: 'proto.CellService', rpc_method: 'GetCellInfo' }

        allow(Gitlab::TopologyServiceClient::Metrics).to receive(:new).and_return(metrics)
        allow(metrics).to receive(:build_labels).and_return(labels)
        allow(metrics).to receive(:increment_rpc_calls_total)
        allow(metrics).to receive(:observe_rpc_duration)
        allow(metrics).to receive(:observe_request_size)
        allow(metrics).to receive(:observe_response_size)

        interceptor.request_response(request: request, call: call, method: method, metadata: metadata) { response }

        expect(metrics).to have_received(:observe_request_size).with(labels: labels, size_bytes: 100)
        expect(metrics).to have_received(:observe_response_size).with(labels: labels, size_bytes: 200)
      end
    end

    context 'with string messages' do
      it 'records request and response sizes' do
        request = 'test request'
        response = 'test response'

        metrics = instance_double(Gitlab::TopologyServiceClient::Metrics)
        labels = { rpc_service: 'proto.CellService', rpc_method: 'GetCellInfo' }

        allow(Gitlab::TopologyServiceClient::Metrics).to receive(:new).and_return(metrics)
        allow(metrics).to receive(:build_labels).and_return(labels)
        allow(metrics).to receive(:increment_rpc_calls_total)
        allow(metrics).to receive(:observe_rpc_duration)
        allow(metrics).to receive(:observe_request_size)
        allow(metrics).to receive(:observe_response_size)

        interceptor.request_response(request: request, call: call, method: method, metadata: metadata) { response }

        expect(metrics).to have_received(:observe_request_size).with(labels: labels, size_bytes: request.bytesize)
        expect(metrics).to have_received(:observe_response_size).with(labels: labels, size_bytes: response.bytesize)
      end
    end

    context 'with zero-size messages' do
      it 'does not record request or response sizes when they are zero' do
        request = nil
        response = nil

        metrics = instance_double(Gitlab::TopologyServiceClient::Metrics)
        labels = { rpc_service: 'proto.CellService', rpc_method: 'GetCellInfo' }

        allow(Gitlab::TopologyServiceClient::Metrics).to receive(:new).and_return(metrics)
        allow(metrics).to receive(:build_labels).and_return(labels)
        allow(metrics).to receive(:increment_rpc_calls_total)
        allow(metrics).to receive(:observe_rpc_duration)
        allow(metrics).to receive(:observe_request_size)
        allow(metrics).to receive(:observe_response_size)

        interceptor.request_response(request: request, call: call, method: method, metadata: metadata) { response }

        expect(metrics).not_to have_received(:observe_request_size)
        expect(metrics).not_to have_received(:observe_response_size)
      end
    end
  end

  describe '#estimate_message_size edge cases' do
    it 'handles messages with encode method' do
      message = double('message') # rubocop:disable RSpec/VerifiedDoubles -- Generic test double
      encoded = 'encoded message'

      allow(message).to receive(:respond_to?).with(:to_proto).and_return(false)
      allow(message).to receive(:is_a?).with(String).and_return(false)
      allow(message).to receive(:respond_to?).with(:encode).and_return(true)
      allow(message).to receive(:encode).with('utf-8').and_return(encoded)

      size = interceptor.send(:estimate_message_size, message)

      expect(size).to eq(encoded.bytesize)
    end

    it 'handles error during size estimation' do
      message = double('message') # rubocop:disable RSpec/VerifiedDoubles -- Generic test double

      allow(message).to receive(:respond_to?).with(:to_proto).and_return(true)
      allow(message).to receive(:to_proto).and_raise(StandardError.new('Serialization error'))

      size = interceptor.send(:estimate_message_size, message)

      expect(size).to eq(0)
    end
  end

  describe '#classify_error additional network errors' do
    it 'classifies ECONNRESET as network_error' do
      error = Errno::ECONNRESET.new
      classification = interceptor.send(:classify_error, error)

      expect(classification).to eq('network_error')
    end

    it 'classifies EHOSTUNREACH as network_error' do
      error = Errno::EHOSTUNREACH.new
      classification = interceptor.send(:classify_error, error)

      expect(classification).to eq('network_error')
    end

    it 'classifies ENETUNREACH as network_error' do
      error = Errno::ENETUNREACH.new
      classification = interceptor.send(:classify_error, error)

      expect(classification).to eq('network_error')
    end

    it 'classifies unknown gRPC status code as unknown_error' do
      # Use a status code that doesn't have a mapping
      error = GRPC::BadStatus.new(999, 'Unknown status')
      classification = interceptor.send(:classify_error, error)

      expect(classification).to eq('unknown_error')
    end
  end
end
