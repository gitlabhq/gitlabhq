# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Subscribers::LoadBalancing, :request_store, feature_category: :cell do
  let(:subscriber) { described_class.new }

  describe '#caught_up_replica_pick' do
    shared_examples 'having payload result value' do |result, counter_name|
      subject { subscriber.caught_up_replica_pick(event) }

      let(:payload) { { result: result } }

      let(:event) do
        double(
          :event,
          name: 'load_balancing.caught_up_replica_pick',
          payload: payload
        )
      end

      it 'stores per-request caught up replica search result' do
        subject

        expect(Gitlab::SafeRequestStore[counter_name]).to eq(1)
      end
    end

    it_behaves_like 'having payload result value', true, :caught_up_replica_pick_ok
    it_behaves_like 'having payload result value', false, :caught_up_replica_pick_fail
  end

  describe "#web_transaction_completed" do
    subject { subscriber.web_transaction_completed(event) }

    let(:event) do
      double(
        :event,
        name: 'load_balancing.web_transaction_completed',
        payload: {}
      )
    end

    let(:web_transaction) { double('Gitlab::Metrics::WebTransaction') }

    before do
      allow(::Gitlab::Metrics::WebTransaction).to receive(:current)
        .and_return(web_transaction)
    end

    context 'when no data in request store' do
      before do
        Gitlab::SafeRequestStore[:caught_up_replica_pick] = nil
      end

      it 'does not change the counters' do
        expect(web_transaction).not_to receive(:increment)
      end
    end

    context 'when request store was updated' do
      before do
        Gitlab::SafeRequestStore[:caught_up_replica_pick_ok] = 2
        Gitlab::SafeRequestStore[:caught_up_replica_pick_fail] = 1
      end

      it 'increments :caught_up_replica_pick count with proper label' do
        expect(web_transaction).to receive(:increment).with(:gitlab_transaction_caught_up_replica_pick_count_total, 2, { result: true })
        expect(web_transaction).to receive(:increment).with(:gitlab_transaction_caught_up_replica_pick_count_total, 1, { result: false })

        subject
      end
    end
  end

  describe '.load_balancing_payload' do
    subject { described_class.load_balancing_payload }

    context 'when no data in request store' do
      before do
        Gitlab::SafeRequestStore[:caught_up_replica_pick_ok] = nil
        Gitlab::SafeRequestStore[:caught_up_replica_pick_fail] = nil
      end

      it 'returns empty hash' do
        expect(subject).to eq({})
      end
    end

    context 'when request store was updated for a single counter' do
      before do
        Gitlab::SafeRequestStore[:caught_up_replica_pick_ok] = 2
      end

      it 'returns proper payload with only that counter' do
        expect(subject).to eq({ caught_up_replica_pick_ok: 2 })
      end
    end

    context 'when both counters were updated' do
      before do
        Gitlab::SafeRequestStore[:caught_up_replica_pick_ok] = 2
        Gitlab::SafeRequestStore[:caught_up_replica_pick_fail] = 1
      end

      it 'return proper payload' do
        expect(subject).to eq({ caught_up_replica_pick_ok: 2, caught_up_replica_pick_fail: 1 })
      end
    end
  end
end
