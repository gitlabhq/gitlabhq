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

    it 'refuses an update that is not a String' do
      expect { store.append(%w[a b]) }.to raise_error(ArgumentError)
    end

    it 'asks for no compaction while below the threshold', :aggregate_failures do
      result = store.append('update')

      expect(result).not_to be_full
      expect(result).not_to be_compact
    end

    it 'asks for compaction once the log reaches the threshold', :aggregate_failures do
      stub_const("#{described_class}::COMPACTION_THRESHOLD", 2)

      expect(store.append('first')).not_to be_compact
      expect(store.append('second')).to be_compact
    end

    it 'asks one caller only while the log stays uncompacted', :aggregate_failures do
      stub_const("#{described_class}::COMPACTION_THRESHOLD", 2)

      store.append('first')

      expect(store.append('second')).to be_compact
      expect(store.append('third')).not_to be_compact
      expect(store.append('fourth')).not_to be_compact
    end

    it 'asks again once the log has been compacted' do
      stub_const("#{described_class}::COMPACTION_THRESHOLD", 2)

      store.append('first')
      token = store.append('second').compaction_token

      store.replace('snapshot', token)

      expect(store.append('third')).to be_compact
    end

    it 'scopes the compaction claim to a single document' do
      stub_const("#{described_class}::COMPACTION_THRESHOLD", 1)

      store.append('first')

      expect(described_class.new('wiki:Project:1:other').append('first')).to be_compact
    end

    context 'when the log is at its ceiling' do
      before do
        stub_const("#{described_class}::COMPACTION_THRESHOLD", 2)
        stub_const("#{described_class}::MAX_LOG_LENGTH", 2)
      end

      it 'reports the document as full' do
        store.append('first')
        store.append('second')

        expect(store.append('third')).to be_full
      end

      it 'does not store the rejected update' do
        store.append('first')
        store.append('second')

        store.append('third')

        expect(store.updates).to eq(%w[first second])
      end

      it 'does not extend the life of a log it is refusing to write to' do
        store.append('first')
        store.append('second')
        Gitlab::Redis::SharedState.with { |redis| redis.expire(updates_key, 60) }

        store.append('third')

        ttl = Gitlab::Redis::SharedState.with { |redis| redis.ttl(updates_key) }

        expect(ttl).to be <= 60
      end

      it 'accepts updates again once the log has been compacted', :aggregate_failures do
        store.append('first')
        token = store.append('second').compaction_token

        store.replace('snapshot', token)

        expect(store.append('third')).not_to be_full
        expect(store.updates).to eq(%w[snapshot third])
      end

      context 'and the compactor never delivered a snapshot' do
        it 'asks a later caller to compact', :aggregate_failures do
          store.append('first')
          store.append('second')
          expire_compaction_claim

          result = store.append('third')

          expect(result).to be_full
          expect(result).to be_compact
        end

        it 'recovers the document when that caller compacts', :aggregate_failures do
          store.append('first')
          store.append('second')
          expire_compaction_claim

          token = store.append('third').compaction_token
          expect(store.replace('snapshot', token)).to be(true)

          expect(store.append('fourth')).not_to be_full
          expect(store.updates).to eq(%w[snapshot fourth])
        end

        it 'still asks only one caller at a time', :aggregate_failures do
          store.append('first')
          store.append('second')
          expire_compaction_claim

          expect(store.append('third')).to be_compact
          expect(store.append('fourth')).not_to be_compact
        end
      end
    end
  end

  describe '#replace' do
    let(:token) do
      stub_const("#{described_class}::COMPACTION_THRESHOLD", 2)

      store.append('first')
      store.append('second').compaction_token
    end

    it 'swaps the claimed log for the snapshot' do
      store.replace('snapshot', token)

      expect(store.updates).to eq(['snapshot'])
    end

    it 'sets an expiry on the compacted log' do
      store.replace('snapshot', token)

      ttl = Gitlab::Redis::SharedState.with { |redis| redis.ttl(updates_key) }

      expect(ttl).to be_positive
    end

    it 'keeps updates appended while the snapshot was being built', :aggregate_failures do
      claim = token
      store.append('third')

      expect(store.replace('snapshot', claim)).to be(true)
      expect(store.updates).to eq(%w[snapshot third])
    end

    context 'without a valid claim' do
      it 'refuses a token that does not match the outstanding claim', :aggregate_failures do
        token

        expect(store.replace('snapshot', 'not-the-token')).to be(false)
        expect(store.updates).to eq(%w[first second])
      end

      it 'refuses a nil token', :aggregate_failures do
        token

        expect(store.replace('snapshot', nil)).to be(false)
        expect(store.updates).to eq(%w[first second])
      end

      it 'refuses an empty token', :aggregate_failures do
        token

        expect(store.replace('snapshot', '')).to be(false)
        expect(store.updates).to eq(%w[first second])
      end

      [{ 'a' => 'b' }, 1, :sym].each do |bad|
        it "refuses a #{bad.class} token", :aggregate_failures do
          token

          expect(store.replace('snapshot', bad)).to be(false)
          expect(store.updates).to eq(%w[first second])
        end
      end

      it 'refuses an Array carrying the real token, leaving the log intact', :aggregate_failures do
        claim = token

        expect(store.replace('snapshot', [claim, 'x'])).to be(false)
        expect(store.updates).to eq(%w[first second])
        expect(ttl_of(updates_key)).to be_positive
        expect(store.replace('snapshot', claim)).to be(true)
      end

      it 'refuses a snapshot that is not a String', :aggregate_failures do
        claim = token

        expect(store.replace(%w[a b], claim)).to be(false)
        expect(store.updates).to eq(%w[first second])
      end

      it 'refuses a token when no compaction was claimed', :aggregate_failures do
        store.append('only')

        expect(store.replace('snapshot', 'made-up')).to be(false)
        expect(store.updates).to eq(['only'])
      end

      it 'refuses to reuse a token that has already compacted', :aggregate_failures do
        claim = token
        store.replace('snapshot', claim)
        store.append('third')

        expect(store.replace('second-snapshot', claim)).to be(false)
        expect(store.updates).to eq(%w[snapshot third])
      end
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

  def ttl_of(key)
    Gitlab::Redis::SharedState.with { |redis| redis.ttl(key) }
  end

  def expire_compaction_claim
    Gitlab::Redis::SharedState.with do |redis|
      redis.del("collaborative_editing:{#{document_key}}:compaction")
    end
  end
end
