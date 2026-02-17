# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::ConcurrencyLimitInterceptor,
  :clean_gitlab_redis_rate_limiting, feature_category: :cell do
  let(:interceptor) { described_class.new }
  let(:service) { Gitlab::TopologyServiceClient::ConcurrencyLimitService }

  describe '#request_response' do
    let(:tracked_method) { '/gitlab.cells.topology_service.claims.v1.ClaimService/BeginUpdate' }
    let(:untracked_method) { '/gitlab.cells.topology_service.claims.v1.ClaimService/GetClaims' }
    let(:request) { double }
    let(:response) { double }

    context 'with a tracked RPC' do
      context 'when under the limit' do
        before do
          allow(service).to receive(:concurrency_limit).and_return(100)
        end

        it 'yields control to the block' do
          expect { |b| interceptor.request_response(request: request, method: tracked_method, &b) }.to yield_control
        end

        it 'increments and decrements the counter' do
          initial_count = service.concurrent_request_count

          interceptor.request_response(request: request, method: tracked_method) { response }

          final_count = service.concurrent_request_count

          # Counter should be back to initial value after request completes
          expect(final_count).to eq(initial_count)
        end
      end

      context 'when over the limit in enforce mode (feature flag enabled)' do
        before do
          allow(service).to receive(:concurrency_limit).and_return(1)
          # Add an existing request to hit the limit
          service.track_request_start
        end

        it 'raises RESOURCE_EXHAUSTED error' do
          expect do
            interceptor.request_response(request: request, method: tracked_method) { response }
          end.to raise_error(GRPC::ResourceExhausted)
        end

        it 'still cleans up the request tracking after rejection' do
          initial_count = service.concurrent_request_count

          expect do
            interceptor.request_response(request: request, method: tracked_method) { response }
          end.to raise_error(GRPC::ResourceExhausted)

          # The rejected request should not leave a dangling entry
          # Count should be same as before (just the pre-existing request)
          expect(service.concurrent_request_count).to eq(initial_count)
        end

        it 'decrements counter even when request is rejected' do
          # Start with 1 request already tracked
          initial_count = service.concurrent_request_count
          expect(initial_count).to eq(1)

          # Try to make a request that will be rejected
          expect do
            interceptor.request_response(request: request, method: tracked_method) { response }
          end.to raise_error(GRPC::ResourceExhausted)

          # Counter should still be 1 (the rejected request was cleaned up)
          # This verifies the fix for the bug where counter wasn't decremented on rejection
          final_count = service.concurrent_request_count
          expect(final_count).to eq(initial_count)
        end
      end

      context 'when in log-only mode (feature flag disabled)' do
        before do
          stub_feature_flags(topology_service_concurrency_limit: false)
          allow(service).to receive(:concurrency_limit).and_return(1)
          # Add an existing request to hit the limit
          service.track_request_start
        end

        it 'logs warning but allows request to proceed' do
          expect(Gitlab::AppLogger).to receive(:warn).with(
            hash_including(
              message: 'Topology Service concurrency limit would be exceeded',
              mode: 'log_only',
              grpc_method: tracked_method
            )
          )

          expect { |b| interceptor.request_response(request: request, method: tracked_method, &b) }.to yield_control
        end
      end
    end

    context 'with an untracked RPC' do
      before do
        allow(service).to receive(:concurrency_limit).and_return(1)
        # Add an existing request to hit the limit
        service.track_request_start
      end

      it 'skips concurrency tracking and yields immediately' do
        expect(service).not_to receive(:track_request_start)

        expect { |b| interceptor.request_response(request: request, method: untracked_method, &b) }.to yield_control
      end

      it 'does not raise error even when over the limit' do
        expect do
          interceptor.request_response(request: request, method: untracked_method) { response }
        end.not_to raise_error
      end
    end
  end

  describe '#server_streaming' do
    let(:tracked_method) { '/gitlab.cells.topology_service.claims.v1.ClaimService/CommitUpdate' }
    let(:untracked_method) { '/TopologyService/StreamCells' }
    let(:request) { double }
    let(:items) { %w[item1 item2 item3] }
    let(:enum) { items.each }

    context 'with a tracked RPC' do
      before do
        allow(service).to receive(:concurrency_limit).and_return(100)
      end

      it 'returns an enumerator that yields all items' do
        result = interceptor.server_streaming(request: request, method: tracked_method) { enum }

        expect(result.to_a).to eq(items)
      end

      it 'keeps request tracked until enumeration completes' do
        result = interceptor.server_streaming(request: request, method: tracked_method) { enum }

        # Request should still be tracked before enumeration
        expect(service.concurrent_request_count).to eq(1)

        # Consume the enumerator
        result.to_a

        # Request should be cleaned up after enumeration completes
        expect(service.concurrent_request_count).to eq(0)
      end

      it 'cleans up request tracking even if enumeration raises an error' do
        error_enum = Enumerator.new do |yielder|
          yielder.yield 'item1'
          raise StandardError, 'enumeration error'
        end

        result = interceptor.server_streaming(request: request, method: tracked_method) { error_enum }

        expect(service.concurrent_request_count).to eq(1)

        expect { result.to_a }.to raise_error(StandardError, 'enumeration error')

        # Request should be cleaned up even after error
        expect(service.concurrent_request_count).to eq(0)
      end
    end

    context 'with an untracked RPC' do
      it 'skips concurrency tracking and yields immediately' do
        expect(service).not_to receive(:track_request_start)

        result = interceptor.server_streaming(request: request, method: untracked_method) { enum }

        expect(result.to_a).to eq(items)
      end
    end
  end

  describe '#client_streaming' do
    let(:tracked_method) { '/gitlab.cells.topology_service.claims.v1.ClaimService/RollbackUpdate' }
    let(:untracked_method) { '/TopologyService/SendRequests' }
    let(:requests) { double }
    let(:response) { double }

    context 'with a tracked RPC' do
      before do
        allow(service).to receive(:concurrency_limit).and_return(100)
      end

      it 'yields control to the block' do
        expect { |b| interceptor.client_streaming(requests: requests, method: tracked_method, &b) }.to yield_control
      end

      it 'increments and decrements the counter immediately' do
        initial_count = service.concurrent_request_count

        interceptor.client_streaming(requests: requests, method: tracked_method) { response }

        # Counter should be back to initial value after request completes
        expect(service.concurrent_request_count).to eq(initial_count)
      end

      context 'when over the limit in enforce mode' do
        before do
          allow(service).to receive(:concurrency_limit).and_return(1)
          service.track_request_start
        end

        it 'raises RESOURCE_EXHAUSTED error' do
          expect do
            interceptor.client_streaming(requests: requests, method: tracked_method) { response }
          end.to raise_error(GRPC::ResourceExhausted)
        end
      end
    end

    context 'with an untracked RPC' do
      before do
        allow(service).to receive(:concurrency_limit).and_return(1)
        service.track_request_start
      end

      it 'skips concurrency tracking and yields immediately' do
        expect(service).not_to receive(:track_request_start)

        expect { |b| interceptor.client_streaming(requests: requests, method: untracked_method, &b) }.to yield_control
      end
    end
  end

  describe '#bidi_streamer' do
    let(:tracked_method) { '/gitlab.cells.topology_service.claims.v1.ClaimService/BeginUpdate' }
    let(:untracked_method) { '/TopologyService/BidiStream' }
    let(:requests) { double }
    let(:items) { %w[item1 item2 item3] }
    let(:enum) { items.each }

    context 'with a tracked RPC' do
      before do
        allow(service).to receive(:concurrency_limit).and_return(100)
      end

      it 'returns an enumerator that yields all items' do
        result = interceptor.bidi_streamer(requests: requests, method: tracked_method) { enum }

        expect(result.to_a).to eq(items)
      end

      it 'keeps request tracked until enumeration completes' do
        result = interceptor.bidi_streamer(requests: requests, method: tracked_method) { enum }

        # Request should still be tracked before enumeration
        expect(service.concurrent_request_count).to eq(1)

        # Consume the enumerator
        result.to_a

        # Request should be cleaned up after enumeration completes
        expect(service.concurrent_request_count).to eq(0)
      end

      it 'cleans up request tracking even if enumeration raises an error' do
        error_enum = Enumerator.new do |yielder|
          yielder.yield 'item1'
          raise StandardError, 'enumeration error'
        end

        result = interceptor.bidi_streamer(requests: requests, method: tracked_method) { error_enum }

        expect(service.concurrent_request_count).to eq(1)

        expect { result.to_a }.to raise_error(StandardError, 'enumeration error')

        # Request should be cleaned up even after error
        expect(service.concurrent_request_count).to eq(0)
      end

      context 'when over the limit in enforce mode' do
        before do
          allow(service).to receive(:concurrency_limit).and_return(1)
          service.track_request_start
        end

        it 'raises RESOURCE_EXHAUSTED error' do
          expect do
            interceptor.bidi_streamer(requests: requests, method: tracked_method) { enum }
          end.to raise_error(GRPC::ResourceExhausted)
        end
      end
    end

    context 'with an untracked RPC' do
      it 'skips concurrency tracking and yields immediately' do
        expect(service).not_to receive(:track_request_start)

        result = interceptor.bidi_streamer(requests: requests, method: untracked_method) { enum }

        expect(result.to_a).to eq(items)
      end
    end
  end

  describe 'TRACKED_RPCS' do
    it 'includes BeginUpdate, CommitUpdate, and RollbackUpdate' do
      expect(described_class::TRACKED_RPCS).to contain_exactly('BeginUpdate', 'CommitUpdate', 'RollbackUpdate')
    end
  end

  describe 'TRACKED_METHOD_CACHE' do
    let(:method) { '/gitlab.cells.topology_service.claims.v1.ClaimService/BeginUpdate' }

    before do
      described_class::TRACKED_METHOD_CACHE.delete(method)
      # Stub track_request_start to avoid its own extract_method_name call
      allow(service).to receive_messages(
        concurrency_limit: 100,
        track_request_start: 'test-request-id',
        track_request_end: nil
      )
    end

    it 'caches tracked_rpc? results to avoid repeated string operations' do
      # extract_method_name should only be called once for repeated requests
      # because tracked_rpc? caches the result
      expect(service).to receive(:extract_method_name).with(method).once.and_call_original

      2.times do
        interceptor.request_response(request: double, method: method) { double }
      end
    end
  end

  describe '#request_response with blank method' do
    let(:request) { double }
    let(:response) { double }

    it 'skips concurrency tracking when method is nil' do
      expect(service).not_to receive(:track_request_start)

      expect { |b| interceptor.request_response(request: request, method: nil, &b) }.to yield_control
    end

    it 'skips concurrency tracking when method is empty string' do
      expect(service).not_to receive(:track_request_start)

      expect { |b| interceptor.request_response(request: request, method: '', &b) }.to yield_control
    end
  end

  describe 'wrap_streaming_response! with nil enum' do
    let(:tracked_method) { '/gitlab.cells.topology_service.claims.v1.ClaimService/BeginUpdate' }
    let(:request) { double }

    before do
      allow(service).to receive(:concurrency_limit).and_return(100)
    end

    it 'returns nil when the block yields nil' do
      result = interceptor.server_streaming(request: request, method: tracked_method) { nil }

      expect(result).to be_nil
    end

    it 'still cleans up request tracking when enum is nil' do
      interceptor.server_streaming(request: request, method: tracked_method) { nil }

      expect(service.concurrent_request_count).to eq(0)
    end
  end

  describe 'error tracking in streaming responses' do
    let(:tracked_method) { '/gitlab.cells.topology_service.claims.v1.ClaimService/CommitUpdate' }
    let(:request) { double }
    let(:error) { StandardError.new('streaming error') }

    before do
      allow(service).to receive(:concurrency_limit).and_return(100)
    end

    it 'tracks exceptions via ErrorTracking when enumeration fails' do
      error_enum = Enumerator.new do |yielder|
        yielder.yield 'item1'
        raise error
      end

      result = interceptor.server_streaming(request: request, method: tracked_method) { error_enum }

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        error,
        hash_including(:request_id)
      )

      expect { result.to_a }.to raise_error(StandardError, 'streaming error')
    end
  end

  describe 'request tracking with grpc_method parameter' do
    let(:tracked_method) { '/gitlab.cells.topology_service.claims.v1.ClaimService/BeginUpdate' }
    let(:request) { double }
    let(:response) { double }

    before do
      allow(service).to receive(:concurrency_limit).and_return(100)
    end

    it 'passes the grpc_method to track_request_start' do
      expect(service).to receive(:track_request_start).with(grpc_method: tracked_method).and_call_original

      interceptor.request_response(request: request, method: tracked_method) { response }
    end
  end
end
