# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::Call, feature_category: :gitaly do
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
      allow(client).to receive(:execute) { response }
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

      expect(client).to receive(:execute).with(
        storage, service, rpc, request,
        remote_storage: remote_storage, timeout: timeout, gitaly_context: gitaly_context
      ).and_return(response)

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
  end
end
