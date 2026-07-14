# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::Call, :clean_gitlab_redis_rate_limiting, feature_category: :gitaly do
  describe '#call', :request_store do
    let(:client) { Gitlab::GitalyClient }
    let(:storage) { 'default' }
    let(:remote_storage) { nil }
    let(:request) { Gitaly::FindLocalBranchesRequest.new }
    let(:rpc) { :find_local_branches }
    let(:service) { :ref_service }
    let(:timeout) { client.long_timeout }
    let(:gitaly_context) { { key: :value } }

    subject do
      described_class.new(storage, service, rpc, request, remote_storage, timeout, gitaly_context: gitaly_context).call
    end

    before do
      allow(client).to receive(:execute) {
        instance_double(GRPC::ActiveCall::Operation, execute: response, trailing_metadata: {})
      }
      allow(Gitlab::PerformanceBar).to receive(:enabled_for_request?) { true }
    end

    def expect_call_details_to_match(duration_higher_than: 0)
      expect(client.list_call_details.size).to eq(1)
      expect(client.list_call_details.first)
        .to match a_hash_including(
          start: a_value > 0,
          feature: "#{service}##{rpc}",
          duration: a_value > duration_higher_than,
          request: an_instance_of(Hash),
          rpc: rpc,
          backtrace: an_instance_of(Array)
        )
    end

    it 'proxy provided arguments to GitalyClient.execute' do
      response = 'response'
      operation = instance_double(GRPC::ActiveCall::Operation, execute: response, trailing_metadata: {})

      expect(client).to receive(:execute).with(
        storage, service, rpc, request,
        remote_storage: remote_storage, timeout: timeout, gitaly_context: gitaly_context
      ).and_return(operation)

      expect(subject).to eq(response)
    end

    context 'when the response is not an enumerator' do
      let(:response) do
        Gitaly::FindLocalBranchesResponse.new
      end

      it 'returns the response' do
        expect(subject).to eq(response)
      end

      it 'stores timings and call details' do
        subject

        expect(client.query_time).to be > 0
        expect_call_details_to_match
      end

      context 'when the call raises an standard error' do
        before do
          allow(client).to receive(:execute).and_raise(StandardError)
        end

        it 'stores timings and call details' do
          expect { subject }.to raise_error(StandardError)

          expect(client.query_time).to be > 0
          expect_call_details_to_match
        end
      end

      context 'when the call raises a BadStatus error' do
        before do
          allow(client).to receive(:execute).and_raise(GRPC::Unavailable)
        end

        it 'attaches gitaly metadata' do
          expect { subject }.to raise_error do |err|
            expect(err.metadata).to eql(
              gitaly_error_metadata: {
                storage: storage,
                address: client.address(storage),
                service: service,
                rpc: rpc
              }
            )
          end
        end
      end
    end

    context 'when the response is an enumerator' do
      let(:response) do
        Enumerator.new do |yielder|
          yielder << 1
          yielder << 2
        end
      end

      it 'returns a consumable enumerator' do
        instrumented_response = subject

        expect(instrumented_response).to be_a(Enumerator)
        expect(instrumented_response.to_a).to eq([1, 2])
      end

      context 'time measurements' do
        let(:response) do
          Enumerator.new do |yielder|
            sleep 0.1
            yielder << 1
            sleep 0.2
            yielder << 2
          end
        end

        it 'records full rpc stream consumption' do
          subject.to_a

          expect(client.query_time).to be > 0.3
          expect_call_details_to_match(duration_higher_than: 0.3)
        end

        it 'records partial rpc stream consumption' do
          subject.first

          expect(client.query_time).to be > 0.1
          expect_call_details_to_match(duration_higher_than: 0.1)
        end

        context 'when the call raises an standard error' do
          let(:response) do
            Enumerator.new do |yielder|
              sleep 0.2
              yielder << 1
              raise StandardError
            end
          end

          it 'records partial rpc stream consumption' do
            expect { subject.to_a }.to raise_error(StandardError)

            expect(client.query_time).to be > 0.2
            expect_call_details_to_match(duration_higher_than: 0.2)
          end
        end

        context 'when the call raises a BadStatus error' do
          let(:response) do
            Enumerator.new do |yielder|
              yielder << 1
              raise GRPC::Unavailable
            end
          end

          it 'attaches gitaly metadata' do
            expect { subject.to_a }.to raise_error do |err|
              expect(err.metadata).to eql(
                gitaly_error_metadata: {
                  storage: storage,
                  address: client.address(storage),
                  service: service,
                  rpc: rpc
                }
              )
            end
          end
        end
      end
    end

    describe 'cost accumulation' do
      let(:cost_trailer) { '3' }
      let(:trailing_metadata) { { 'x-gitaly-cost' => cost_trailer } }
      let(:operation) do
        instance_double(GRPC::ActiveCall::Operation, execute: response, trailing_metadata: trailing_metadata)
      end

      # Fresh Call instance; the outer `subject` is memoized which prevents
      # exercising multiple sequential calls within one example.
      def make_call
        described_class.new(
          storage, service, rpc, request, remote_storage, timeout, gitaly_context: gitaly_context
        ).call
      end

      before do
        allow(client).to receive(:execute) { operation }
      end

      context 'when the response is unary' do
        let(:response) { Gitaly::FindLocalBranchesResponse.new }

        it 'accumulates the cost from the trailer' do
          subject

          expect(Gitlab::RequestCost.current.get(:gitaly)).to eq(3)
        end
      end

      context 'when the response is a stream' do
        let(:response) do
          Enumerator.new do |yielder|
            yielder << 1
            yielder << 2
          end
        end

        it 'accumulates the cost after the stream is consumed' do
          subject.to_a

          expect(Gitlab::RequestCost.current.get(:gitaly)).to eq(3)
        end

        it 'does not accumulate before the stream is consumed' do
          subject

          expect(Gitlab::RequestCost.current.get(:gitaly)).to eq(0)
        end
      end

      context 'when multiple RPCs are dispatched' do
        let(:response) { Gitaly::FindLocalBranchesResponse.new }

        it 'sums cost across calls' do
          3.times { make_call }

          expect(Gitlab::RequestCost.current.get(:gitaly)).to eq(9)
        end
      end

      context 'when a mix of unary and streaming RPCs are dispatched' do
        # Each Call has its own operation but the cost goes into the shared
        # SafeRequestStore, so the total across mixed RPC types accumulates.
        let(:response) { Gitaly::FindLocalBranchesResponse.new } # placeholder

        it 'accumulates total cost across all RPC shapes' do
          # unary, cost 2
          allow(client).to receive(:execute) {
            instance_double(GRPC::ActiveCall::Operation,
              execute: Gitaly::FindLocalBranchesResponse.new,
              trailing_metadata: { 'x-gitaly-cost' => '2' })
          }
          make_call

          # streaming, cost 5
          allow(client).to receive(:execute) {
            instance_double(GRPC::ActiveCall::Operation,
              execute: Enumerator.new { |y| y << 1 },
              trailing_metadata: { 'x-gitaly-cost' => '5' })
          }
          make_call.to_a

          # unary, cost 1
          allow(client).to receive(:execute) {
            instance_double(GRPC::ActiveCall::Operation,
              execute: Gitaly::FindLocalBranchesResponse.new,
              trailing_metadata: { 'x-gitaly-cost' => '1' })
          }
          make_call

          expect(Gitlab::RequestCost.current.get(:gitaly)).to eq(8)
        end
      end

      context 'when the trailer cost is zero' do
        let(:response) { Gitaly::FindLocalBranchesResponse.new }
        let(:cost_trailer) { '0' }

        it 'does not accumulate' do
          subject

          expect(Gitlab::RequestCost.current.get(:gitaly)).to eq(0)
        end
      end

      context 'when the trailer is missing the cost key' do
        let(:response) { Gitaly::FindLocalBranchesResponse.new }
        let(:trailing_metadata) { {} }

        it 'does not accumulate' do
          subject

          expect(Gitlab::RequestCost.current.get(:gitaly)).to eq(0)
        end
      end

      context 'when trailing_metadata is nil' do
        let(:response) { Gitaly::FindLocalBranchesResponse.new }
        let(:trailing_metadata) { nil }

        it 'does not fail' do
          subject

          expect(Gitlab::RequestCost.current.get(:gitaly)).to eq(0)
        end
      end

      context 'when reading trailing_metadata raises an error' do
        let(:response) { Gitaly::FindLocalBranchesResponse.new }

        before do
          allow(operation).to receive(:trailing_metadata).and_raise(StandardError, 'connection reset')
        end

        it 'logs a warning and does not propagate the error' do
          expect(Gitlab::AppLogger).to receive(:warn).with(
            message: "Failed to accumulate Gitaly cost",
            error_class: "StandardError",
            error_message: "connection reset"
          )

          subject

          expect(Gitlab::RequestCost.current.get(:gitaly)).to eq(0)
        end
      end

      context 'when the feature flag is disabled' do
        let(:response) { Gitaly::FindLocalBranchesResponse.new }

        before do
          stub_feature_flags(request_cost_headers: false)
        end

        it 'does not read the trailer or accumulate cost' do
          expect(operation).not_to receive(:trailing_metadata)

          subject

          expect(Gitlab::RequestCost.current.get(:gitaly)).to eq(0)
        end
      end
    end

    describe 'gitaly_client_calls SLI' do
      let(:subject_call) do
        described_class.new(storage, service, rpc, request, remote_storage, timeout, gitaly_context: gitaly_context)
      end

      context 'when the response is not an enumerator' do
        let(:response) { Gitaly::FindLocalBranchesResponse.new }

        it 'records a successful call with no error' do
          expect(Gitlab::Metrics::GitalyClientSlis).to receive(:record_error_rate).with(
            storage: storage, error: nil
          ).once

          subject
        end

        context 'when the call raises a BadStatus error' do
          before do
            allow(client).to receive(:execute).and_raise(GRPC::Unavailable)
          end

          it 'records the call passing the exception' do
            expect(Gitlab::Metrics::GitalyClientSlis).to receive(:record_error_rate).with(
              storage: storage, error: an_instance_of(GRPC::Unavailable)
            ).once

            expect { subject }.to raise_error(GRPC::Unavailable)
          end
        end

        context 'when the circuit breaker is open' do
          before do
            allow(subject_call.send(:circuit_breaker)).to receive(:check!)
              .and_raise(Gitlab::Git::ResourceExhaustedError)
          end

          it 'records the call passing the exception' do
            expect(Gitlab::Metrics::GitalyClientSlis).to receive(:record_error_rate).with(
              storage: storage, error: an_instance_of(Gitlab::Git::ResourceExhaustedError)
            ).once

            expect { subject_call.call }.to raise_error(Gitlab::Git::ResourceExhaustedError)
          end
        end
      end

      context 'when the response is an enumerator' do
        let(:response) do
          Enumerator.new do |yielder|
            yielder << 1
            yielder << 2
          end
        end

        it 'records a successful call once the stream is consumed' do
          expect(Gitlab::Metrics::GitalyClientSlis).to receive(:record_error_rate).with(
            storage: storage, error: nil
          ).once

          subject.to_a
        end

        context 'when the stream raises a BadStatus error' do
          let(:response) do
            Enumerator.new do |yielder|
              yielder << 1
              raise GRPC::Unavailable
            end
          end

          it 'records the call once passing the exception' do
            expect(Gitlab::Metrics::GitalyClientSlis).to receive(:record_error_rate).with(
              storage: storage, error: an_instance_of(GRPC::Unavailable)
            ).once

            expect { subject.to_a }.to raise_error(GRPC::Unavailable)
          end
        end
      end
    end

    describe 'circuit breaker integration' do
      let(:exhausted_exception) { GRPC::ResourceExhausted.new("Gitaly exhausted") }

      before do
        allow(Gitlab::GitalyClient).to receive(:stub).and_return(double)
      end

      it 'opens circuit after threshold of ResourceExhausted errors' do
        unique_rpc = :"find_branch_#{SecureRandom.hex(4)}"

        allow(Gitlab::GitalyClient).to receive(:execute).and_raise(exhausted_exception)

        gitaly_call = described_class.new(storage, service, unique_rpc, request, nil, 10)

        5.times do
          expect { gitaly_call.call }.to raise_error(GRPC::ResourceExhausted)
        end

        expect(Gitlab::GitalyClient).not_to receive(:execute)

        expect { gitaly_call.call }.to raise_error(Gitlab::Git::ResourceExhaustedError, /Circuit is open/)
      end

      context 'with streaming enumerator responses' do
        it 'opens circuit when enumerator consumption fails with ResourceExhausted' do
          unique_rpc = :"find_branch_#{SecureRandom.hex(4)}"
          allow(Gitlab::GitalyClient).to receive(:execute) do
            instance_double(GRPC::ActiveCall::Operation,
              execute: Enumerator.new { raise exhausted_exception },
              trailing_metadata: {})
          end

          gitaly_call = described_class.new(storage, service, unique_rpc, request, nil, 10)

          # Fail 5 times during enumerator consumption (Circuitbox default threshold)
          5.times do
            response = gitaly_call.call
            expect { response.to_a }.to raise_error(GRPC::ResourceExhausted)
          end

          expect(Gitlab::GitalyClient).not_to receive(:execute)

          # Circuit should now be open
          expect { gitaly_call.call }.to raise_error(Gitlab::Git::ResourceExhaustedError, /Circuit is open/)
        end
      end
    end
  end
end
