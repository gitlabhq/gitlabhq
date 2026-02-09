# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::CircuitBreaker, :clean_gitlab_redis_rate_limiting, feature_category: :gitaly do
  subject(:circuit_breaker) { described_class.new(service: service, rpc: rpc, storage: storage) }

  let(:service) { :ref_service }
  let(:storage) { 'default' }
  # Use unique rpc name per example to avoid circuit state leaking between tests
  let(:rpc) { :"find_branch_#{SecureRandom.hex(4)}" }
  let(:resource_exhausted_error) { GRPC::ResourceExhausted.new('Gitaly exhausted') }

  describe '#call' do
    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(add_circuit_breaker_to_gitaly: false)
      end

      it 'executes block without circuit breaker' do
        result = circuit_breaker.call { 'success' }

        expect(result).to eq('success')
      end

      it 'does not open circuit after multiple failures' do
        15.times do
          expect { circuit_breaker.call { raise resource_exhausted_error } }
            .to raise_error(GRPC::ResourceExhausted)
        end
      end
    end

    context 'when feature flag is enabled' do
      context 'when request is authenticated' do
        let(:user) { build(:user) }

        it 'bypasses circuit breaker and executes block' do
          Gitlab::ApplicationContext.with_context(user: user) do
            result = circuit_breaker.call { 'success' }

            expect(result).to eq('success')
          end
        end

        it 'does not open circuit after multiple failures' do
          Gitlab::ApplicationContext.with_context(user: user) do
            15.times do
              expect { circuit_breaker.call { raise resource_exhausted_error } }
                .to raise_error(GRPC::ResourceExhausted)
            end
          end
        end
      end

      context 'when request is unauthenticated' do
        it 'executes block successfully' do
          result = circuit_breaker.call { 'success' }

          expect(result).to eq('success')
        end

        it 'opens circuit after threshold of ResourceExhausted errors' do
          # Circuitbox default: volume_threshold=5, error_threshold=50 (percentage)
          # Need at least 5 requests with >50% failure rate to open circuit
          5.times do
            expect { circuit_breaker.call { raise resource_exhausted_error } }
              .to raise_error(GRPC::ResourceExhausted)
          end

          expect { circuit_breaker.call { 'should not execute' } }
            .to raise_error(Gitlab::Git::ResourceExhaustedError, /Circuit is open/)
        end

        it 'does not catch other exceptions' do
          15.times do
            expect { circuit_breaker.call { raise GRPC::Internal, 'internal error' } }
              .to raise_error(GRPC::Internal)
          end
        end

        it 'isolates circuits by service and rpc' do
          rpc1 = :"find_branch_#{SecureRandom.hex(4)}"
          rpc2 = :"find_tag_#{SecureRandom.hex(4)}"
          cb1 = described_class.new(service: :ref_service, rpc: rpc1, storage: storage)
          cb2 = described_class.new(service: :ref_service, rpc: rpc2, storage: storage)

          5.times do
            expect { cb1.call { raise resource_exhausted_error } }
              .to raise_error(GRPC::ResourceExhausted)
          end

          expect { cb1.call { 'test' } }
            .to raise_error(Gitlab::Git::ResourceExhaustedError, /Circuit is open/)

          expect { cb2.call { 'success' } }.not_to raise_error
        end

        it 'isolates circuits by storage' do
          storage1 = 'default'
          storage2 = 'storage-2'
          rpc_name = :"find_branch_#{SecureRandom.hex(4)}"

          cb1 = described_class.new(service: :ref_service, rpc: rpc_name, storage: storage1)
          cb2 = described_class.new(service: :ref_service, rpc: rpc_name, storage: storage2)

          # Open circuit for storage1
          5.times do
            expect { cb1.call { raise resource_exhausted_error } }
              .to raise_error(GRPC::ResourceExhausted)
          end

          expect { cb1.call { 'test' } }
            .to raise_error(Gitlab::Git::ResourceExhaustedError, /Circuit is open/)

          # storage2 should not be affected
          expect { cb2.call { 'success' } }.not_to raise_error
        end
      end

      context 'when switching between authenticated and unauthenticated' do
        let(:user) { build(:user) }

        it 'respects authentication context' do
          # Open circuit with unauthenticated requests
          5.times do
            expect { circuit_breaker.call { raise resource_exhausted_error } }
              .to raise_error(GRPC::ResourceExhausted)
          end

          expect { circuit_breaker.call { 'test' } }
            .to raise_error(Gitlab::Git::ResourceExhaustedError, /Circuit is open/)

          # Authenticated request bypasses circuit
          Gitlab::ApplicationContext.with_context(user: user) do
            expect { circuit_breaker.call { raise resource_exhausted_error } }
              .to raise_error(GRPC::ResourceExhausted)
          end

          # Back to unauthenticated - circuit still open
          expect { circuit_breaker.call { 'test' } }
            .to raise_error(Gitlab::Git::ResourceExhaustedError, /Circuit is open/)
        end
      end

      context 'when Redis is unavailable' do
        before do
          allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
          allow(Gitlab::Redis::RateLimiting)
            .to receive(:with)
            .and_raise(Redis::BaseConnectionError)
        end

        it 'allows requests through when circuit state cannot be determined' do
          # Circuit breaker fails open: when Redis is unavailable, requests proceed normally
          # This prevents Redis from becoming a single point of failure
          result = circuit_breaker.call { 'success' }

          expect(result).to eq('success')
        end

        it 'does not prevent check! from passing' do
          # When Redis is unavailable, check! should not raise an error
          # The circuit is treated as closed (safe default)
          expect { circuit_breaker.check! }.not_to raise_error
        end

        it 'allows failures to propagate without circuit breaker interference' do
          # Even when Redis is down, actual Gitaly errors should still be raised
          expect { circuit_breaker.call { raise resource_exhausted_error } }
            .to raise_error(GRPC::ResourceExhausted)
        end
      end
    end
  end

  describe '#check!' do
    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(add_circuit_breaker_to_gitaly: false)
      end

      it 'does not raise even after multiple failures' do
        15.times do
          expect { circuit_breaker.call { raise resource_exhausted_error } }
            .to raise_error(GRPC::ResourceExhausted)
        end

        expect { circuit_breaker.check! }.not_to raise_error
      end
    end

    context 'when feature flag is enabled' do
      context 'when request is authenticated' do
        let(:user) { build(:user) }

        it 'does not raise when circuit is open' do
          5.times do
            expect { circuit_breaker.call { raise resource_exhausted_error } }
              .to raise_error(GRPC::ResourceExhausted)
          end

          Gitlab::ApplicationContext.with_context(user: user) do
            expect { circuit_breaker.check! }.not_to raise_error
          end
        end
      end

      context 'when request is unauthenticated' do
        it 'does not raise when circuit is closed' do
          expect { circuit_breaker.check! }.not_to raise_error
        end

        it 'raises ResourceExhaustedError when circuit is open' do
          5.times do
            expect { circuit_breaker.call { raise resource_exhausted_error } }
              .to raise_error(GRPC::ResourceExhausted)
          end

          expect { circuit_breaker.check! }
            .to raise_error(Gitlab::Git::ResourceExhaustedError, /Circuit is open/)
        end

        it 'does not count as a failure' do
          # 4 failures - not enough to open circuit
          4.times do
            expect { circuit_breaker.call { raise resource_exhausted_error } }
              .to raise_error(GRPC::ResourceExhausted)
          end

          # Multiple check! calls should not contribute to failure count
          10.times { circuit_breaker.check! }

          # Circuit should still be closed since we only had 4 failures
          expect { circuit_breaker.call { 'success' } }.not_to raise_error
        end
      end
    end
  end
end
