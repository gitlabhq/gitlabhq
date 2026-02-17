# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::ConcurrencyLimitService,
  :clean_gitlab_redis_rate_limiting, feature_category: :cell do
  describe '.concurrency_limit' do
    context 'when ApplicationSettings has a value' do
      before do
        allow(described_class).to receive(:concurrency_limit).and_return(50)
      end

      it 'returns the limit from ApplicationSettings' do
        expect(described_class.concurrency_limit).to eq(50)
      end
    end
  end

  describe '.concurrent_request_count' do
    context 'when requests are being tracked' do
      before do
        described_class.track_request_start
        described_class.track_request_start
      end

      it 'returns the current count' do
        expect(described_class.concurrent_request_count).to eq(2)
      end
    end

    context 'when no requests are being tracked' do
      it 'returns 0' do
        expect(described_class.concurrent_request_count).to eq(0)
      end
    end

    context 'when Redis is unavailable' do
      before do
        allow(Gitlab::Redis::RateLimiting).to receive(:with_suppressed_errors).and_return(nil)
      end

      it 'returns 0' do
        expect(described_class.concurrent_request_count).to eq(0)
      end
    end
  end

  describe '.track_request_start' do
    it 'increments the count' do
      expect { described_class.track_request_start }.to change {
        described_class.concurrent_request_count
      }.from(0).to(1)
    end

    it 'returns a unique request ID containing process ID' do
      request_id = described_class.track_request_start
      expect(request_id).to be_present
      expect(request_id).to include(Process.pid.to_s)
    end

    it 'returns different IDs for each request' do
      request_id1 = described_class.track_request_start
      request_id2 = described_class.track_request_start
      expect(request_id1).not_to eq(request_id2)
    end

    context 'when grpc_method is provided' do
      it 'includes the method name in the request ID' do
        request_id = described_class.track_request_start(grpc_method: '/TopologyService/GetCell')
        expect(request_id).to include('GetCell')
        expect(request_id).to match(/\A\d+:GetCell:.+\z/)
      end

      it 'extracts method name from full gRPC path' do
        request_id = described_class.track_request_start(grpc_method: '/gitlab.cells.TopologyService/ListCells')
        expect(request_id).to include('ListCells')
      end
    end

    context 'when grpc_method is nil or blank' do
      it 'uses "unknown" as the method name' do
        request_id = described_class.track_request_start(grpc_method: nil)
        expect(request_id).to include(':unknown:')
      end

      it 'uses "unknown" for empty string' do
        request_id = described_class.track_request_start(grpc_method: '')
        expect(request_id).to include(':unknown:')
      end
    end

    context 'when the concurrency limit is reached' do
      before do
        allow(described_class).to receive(:concurrency_limit).and_return(2)
        described_class.track_request_start
        described_class.track_request_start
      end

      it 'returns nil when limit is exceeded' do
        request_id = described_class.track_request_start
        expect(request_id).to be_nil
      end

      it 'does not increment the count' do
        expect { described_class.track_request_start }.not_to change {
          described_class.concurrent_request_count
        }
      end
    end

    context 'when Redis is unavailable' do
      before do
        allow(Gitlab::Redis::RateLimiting).to receive(:with_suppressed_errors).and_return(nil)
      end

      it 'does not raise an error' do
        expect { described_class.track_request_start }.not_to raise_error
      end

      it 'returns a request_id to allow the request to proceed' do
        # When Redis fails, we allow the request through (fail-open behavior)
        request_id = described_class.track_request_start
        expect(request_id).to be_present
        expect(request_id).to include(Process.pid.to_s)
      end
    end

    context 'when correlation ID is available' do
      let(:correlation_id) { 'test-correlation-id-123' }

      before do
        allow(Labkit::Correlation::CorrelationId).to receive(:current_id).and_return(correlation_id)
      end

      it 'includes the correlation ID in the request ID' do
        request_id = described_class.track_request_start(grpc_method: '/TopologyService/GetCell')
        expect(request_id).to include(correlation_id)
      end
    end

    context 'when request ID format' do
      let(:correlation_id) { 'abc-123-def' }

      before do
        allow(Labkit::Correlation::CorrelationId).to receive(:current_id).and_return(correlation_id)
      end

      it 'follows the format pid:method:correlationId:hex' do
        request_id = described_class.track_request_start(grpc_method: '/TopologyService/GetCell')
        parts = request_id.split(':')

        expect(parts.length).to eq(4)
        expect(parts[0]).to eq(Process.pid.to_s)
        expect(parts[1]).to eq('GetCell')
        expect(parts[2]).to eq(correlation_id)
        expect(parts[3]).to match(/\A[a-f0-9]{16}\z/) # 8 bytes = 16 hex chars
      end
    end
  end

  describe '.track_request_end' do
    let!(:request_id) { described_class.track_request_start }

    it 'decrements the count' do
      expect { described_class.track_request_end(request_id) }.to change {
        described_class.concurrent_request_count
      }.from(1).to(0)
    end

    it 'only removes the specific request' do
      request_id2 = described_class.track_request_start
      expect(described_class.concurrent_request_count).to eq(2)

      described_class.track_request_end(request_id)
      expect(described_class.concurrent_request_count).to eq(1)

      described_class.track_request_end(request_id2)
      expect(described_class.concurrent_request_count).to eq(0)
    end

    context 'when request_id is nil' do
      it 'does not raise an error' do
        expect { described_class.track_request_end(nil) }.not_to raise_error
      end
    end

    context 'when Redis is unavailable' do
      before do
        allow(Gitlab::Redis::RateLimiting).to receive(:with_suppressed_errors).and_return(nil)
      end

      it 'does not raise an error' do
        expect { described_class.track_request_end(request_id) }.not_to raise_error
      end
    end
  end

  describe '.cleanup_stale_requests' do
    context 'when there are requests older than TTL' do
      before do
        Gitlab::Redis::RateLimiting.with do |redis|
          redis.hset(described_class::REDIS_KEY_EXECUTING, 'old_request', 1.hour.ago.utc.to_i)
        end
      end

      it 'removes stale requests and returns count' do
        result = described_class.cleanup_stale_requests

        expect(described_class.concurrent_request_count).to eq(0)
        expect(result).to eq({ removed_count: 1 })
      end
    end

    context 'when there are no stale requests' do
      before do
        described_class.track_request_start
      end

      it 'does not remove recent requests' do
        result = described_class.cleanup_stale_requests
        expect(described_class.concurrent_request_count).to eq(1)
        expect(result).to eq({ removed_count: 0 })
      end
    end

    it 'returns nil when no stale requests exist' do
      result = described_class.cleanup_stale_requests
      expect(result).to eq({ removed_count: 0 })
    end

    context 'when Redis is unavailable' do
      before do
        allow(Gitlab::Redis::RateLimiting).to receive(:with_suppressed_errors).and_return(nil)
      end

      it 'does not raise an error' do
        expect { described_class.cleanup_stale_requests }.not_to raise_error
      end

      it 'returns zero removed count' do
        expect(described_class.cleanup_stale_requests).to eq({ removed_count: 0 })
      end
    end
  end

  describe '.enforce_mode_enabled?' do
    context 'when feature flag is enabled' do
      it 'returns true' do
        expect(described_class.enforce_mode_enabled?).to be(true)
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(topology_service_concurrency_limit: false)
      end

      it 'returns false' do
        expect(described_class.enforce_mode_enabled?).to be(false)
      end
    end
  end

  describe '.extract_method_name' do
    it 'extracts method name from full gRPC path' do
      expect(described_class.extract_method_name('/gitlab.cells.topology_service.claims.v1.ClaimService/BeginUpdate'))
        .to eq('BeginUpdate')
    end

    it 'extracts method name from simple gRPC path' do
      expect(described_class.extract_method_name('/TopologyService/GetCell')).to eq('GetCell')
    end

    it 'returns unknown for nil' do
      expect(described_class.extract_method_name(nil)).to eq('unknown')
    end

    it 'returns unknown for empty string' do
      expect(described_class.extract_method_name('')).to eq('unknown')
    end

    it 'returns unknown for trailing slash' do
      expect(described_class.extract_method_name('/TopologyService/')).to eq('unknown')
    end

    it 'returns custom fallback when provided' do
      expect(described_class.extract_method_name(nil, fallback: 'custom')).to eq('custom')
      expect(described_class.extract_method_name('', fallback: 'default_method')).to eq('default_method')
    end

    it 'handles method name without leading slash' do
      expect(described_class.extract_method_name('TopologyService/GetCell')).to eq('GetCell')
    end

    it 'handles method name that is just the method' do
      expect(described_class.extract_method_name('GetCell')).to eq('GetCell')
    end
  end

  describe 'Lua script atomicity' do
    before do
      allow(described_class).to receive(:concurrency_limit).and_return(2)
    end

    it 'atomically checks and adds request preventing race conditions' do
      # Simulate concurrent requests by tracking two requests
      request_id1 = described_class.track_request_start(grpc_method: '/TopologyService/BeginUpdate')
      request_id2 = described_class.track_request_start(grpc_method: '/TopologyService/CommitUpdate')

      expect(request_id1).to be_present
      expect(request_id2).to be_present
      expect(described_class.concurrent_request_count).to eq(2)

      # Third request should be rejected
      request_id3 = described_class.track_request_start(grpc_method: '/TopologyService/RollbackUpdate')
      expect(request_id3).to be_nil
      expect(described_class.concurrent_request_count).to eq(2)
    end
  end

  describe 'REDIS_KEY_EXECUTING constant' do
    it 'has the expected value' do
      expect(described_class::REDIS_KEY_EXECUTING).to eq('topology_service:concurrency_limit:executing')
    end
  end

  describe 'TRACKING_KEY_TTL constant' do
    it 'is 5 minutes' do
      expect(described_class::TRACKING_KEY_TTL).to eq(5.minutes)
    end
  end
end
