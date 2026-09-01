# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CollaborativeEditing::DocumentStore, :clean_gitlab_redis_shared_state,
  feature_category: :wiki do
  let(:document_key) { 'wiki:Project:1:home' }

  subject(:store) { described_class.new(document_key) }

  describe '#updates' do
    it 'is empty for an unknown document' do
      expect(store.updates).to eq([])
    end

    it 'returns appended updates in order' do
      store.append('first')
      store.append('second')

      expect(store.updates).to eq(%w[first second])
    end
  end

  describe '#append' do
    it 'sets an expiry so documents do not accumulate once editing stops' do
      store.append('update')

      ttl = Gitlab::Redis::SharedState.with { |redis| redis.ttl(updates_key) }

      expect(ttl).to be_positive
    end

    it 'refreshes the expiry on every write' do
      store.append('update')
      Gitlab::Redis::SharedState.with { |redis| redis.expire(updates_key, 5) }

      store.append('another update')

      ttl = Gitlab::Redis::SharedState.with { |redis| redis.ttl(updates_key) }

      expect(ttl).to be > 5
    end

    it 'returns false while below the compaction threshold' do
      expect(store.append('update')).to be(false)
    end

    it 'returns true once the log reaches the compaction threshold', :aggregate_failures do
      stub_const("#{described_class}::COMPACTION_THRESHOLD", 2)

      expect(store.append('first')).to be(false)
      expect(store.append('second')).to be(true)
    end

    it 'signals once while the log stays uncompacted', :aggregate_failures do
      stub_const("#{described_class}::COMPACTION_THRESHOLD", 2)

      store.append('first')

      expect(store.append('second')).to be(true)
      expect(store.append('third')).to be(false)
      expect(store.append('fourth')).to be(false)
    end

    it 'signals again once the log has been compacted', :aggregate_failures do
      stub_const("#{described_class}::COMPACTION_THRESHOLD", 2)

      store.append('first')
      expect(store.append('second')).to be(true)

      store.replace('snapshot')

      expect(store.append('third')).to be(true)
    end

    it 'scopes the compaction signal to a single document' do
      stub_const("#{described_class}::COMPACTION_THRESHOLD", 1)

      store.append('first')

      expect(described_class.new('wiki:Project:1:other').append('first')).to be(true)
    end
  end

  describe '#replace' do
    it 'swaps the whole log for the snapshot' do
      store.append('first')
      store.append('second')

      store.replace('snapshot')

      expect(store.updates).to eq(['snapshot'])
    end

    it 'sets an expiry on the replaced log' do
      store.replace('snapshot')

      ttl = Gitlab::Redis::SharedState.with { |redis| redis.ttl(updates_key) }

      expect(ttl).to be_positive
    end
  end

  describe '#claim_seed' do
    it 'succeeds for the first caller only', :aggregate_failures do
      expect(store.claim_seed).to be_truthy
      expect(store.claim_seed).to be_falsey
    end

    it 'scopes the claim to a single document' do
      store.claim_seed

      expect(described_class.new('wiki:Project:1:other').claim_seed).to be_truthy
    end
  end

  def updates_key
    "collaborative_editing:{#{document_key}}:updates"
  end
end
