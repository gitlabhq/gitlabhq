# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::CircuitBreaker::Metrics, :prometheus, feature_category: :gitaly do
  let(:circuit_state) { 'closed' }

  describe '.track_request' do
    subject(:track_request) do
      described_class.track_request(
        circuit_state: circuit_state,
        result: result,
        reason: reason
      )
    end

    let(:reason) { '' }

    context 'with allowed result' do
      let(:result) { 'allowed' }

      it 'increments the requests_total counter' do
        expect { track_request }
          .to change { request_metric_value(result: result, reason: '') }
          .by(1)
      end
    end

    context 'with rejected result' do
      let(:result) { 'rejected' }
      let(:circuit_state) { 'open' }

      it 'increments the requests_total counter' do
        expect { track_request }
          .to change { request_metric_value(circuit_state: 'open', result: result, reason: '') }
          .by(1)
      end
    end

    context 'with error result and reason' do
      let(:result) { 'error' }
      let(:reason) { 'resource_exhausted' }

      it 'increments the requests_total counter with reason' do
        expect { track_request }
          .to change { request_metric_value(result: result, reason: reason) }
          .by(1)
      end
    end

    context 'when reason is not provided' do
      let(:result) { 'allowed' }

      it 'defaults reason to empty string' do
        described_class.track_request(circuit_state: circuit_state, result: result)

        expect(request_metric_value(result: result, reason: '')).to eq(1)
      end
    end
  end

  describe '.track_state_transition' do
    subject(:track_state_transition) do
      described_class.track_state_transition(
        endpoint: endpoint,
        storage: storage,
        from_state: from_state,
        to_state: to_state
      )
    end

    let(:endpoint) { 'ref_service:find_branch' }
    let(:storage) { 'default' }
    let(:from_state) { 'closed' }
    let(:to_state) { 'open' }

    it 'increments the transitions_total counter' do
      expect { track_state_transition }
        .to change { transition_metric_value(from_state: from_state, to_state: to_state) }
        .by(1)
    end

    it 'logs the state transition with endpoint and storage details' do
      expect(Gitlab::AppLogger).to receive(:info).with(
        message: 'Gitaly circuit breaker state transition',
        endpoint: endpoint,
        storage: storage,
        from_state: from_state,
        to_state: to_state
      )

      track_state_transition
    end

    context 'with different endpoint and storage values' do
      let(:endpoint) { 'blob_service:get_blob' }
      let(:storage) { 'nfs-1' }

      it 'logs the correct endpoint and storage' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            endpoint: 'blob_service:get_blob',
            storage: 'nfs-1'
          )
        )

        track_state_transition
      end

      it 'increments the same counter regardless of endpoint/storage' do
        expect { track_state_transition }
          .to change { transition_metric_value(from_state: from_state, to_state: to_state) }
          .by(1)
      end
    end

    context 'when transitioning from open to closed' do
      let(:from_state) { 'open' }
      let(:to_state) { 'closed' }

      it 'increments the correct counter' do
        expect { track_state_transition }
          .to change { transition_metric_value(from_state: 'open', to_state: 'closed') }
          .by(1)
      end
    end
  end

  private

  def request_metric_value(result:, reason:, circuit_state: 'closed')
    described_class.requests_total.get(
      circuit_state: circuit_state,
      result: result,
      reason: reason
    )
  end

  def transition_metric_value(from_state:, to_state:)
    described_class.transitions_total.get(
      from_state: from_state,
      to_state: to_state
    )
  end
end
