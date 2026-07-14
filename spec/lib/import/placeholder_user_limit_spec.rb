# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::PlaceholderUserLimit, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:plan) { create(:default_plan) }

  before_all do
    create(:import_source_user, namespace: namespace)
    create(:import_source_user, :completed, namespace: namespace, placeholder_user: nil)
    create(:import_source_user)
  end

  describe '#exceeded?' do
    let(:instance) { described_class.new(namespace: namespace) }

    subject(:exceeded?) { instance.exceeded? }

    context 'when plan has no limit' do
      it { is_expected.to eq(false) }
    end

    context 'when plan has a limit' do
      before do
        create(:plan_limits, plan: plan, import_placeholder_user_limit_tier_1: limit)
      end

      context 'when limit is 0 (unlimited)' do
        let(:limit) { 0 }

        it { is_expected.to eq(false) }
      end

      context 'when placeholder user count does not exceed the limit' do
        let(:limit) { 2 }

        it { is_expected.to eq(false) }

        it 'does not cache the result' do
          exceeded?

          instance = described_class.new(namespace: namespace)

          expect(instance.send(:cache).read(instance.send(:cache_key))).to be_nil
        end
      end

      context 'when placeholder user count exceeds the limit' do
        let(:limit) { 1 }

        it { is_expected.to eq(true) }

        it 'caches the result' do
          expect(Import::SourceUser).to receive(:namespace_placeholder_user_count).once.and_call_original

          2.times { expect(described_class.new(namespace: namespace).exceeded?).to eq(true) }

          instance = described_class.new(namespace: namespace)
          cache_key = instance.send(:cache_key)

          expect(instance.send(:cache).read(cache_key)).to eq('true')
        end

        it 'logs that the namespace has exceeded the limit' do
          expect(Import::Framework::Logger).to receive(:info).with(
            message: 'Placeholder user limit exceeded for namespace',
            limit: 1
          )

          exceeded?
        end

        it 'reads the cached result using the EXCEEDANCE_CACHE_TTL timeout' do
          exceeded?

          allow(Gitlab::Cache::Import::Caching).to receive(:read).and_call_original

          described_class.new(namespace: namespace).exceeded?

          expect(Gitlab::Cache::Import::Caching)
            .to have_received(:read)
            .with(instance.send(:cache_key), timeout: described_class::EXCEEDANCE_CACHE_TTL)
        end

        it 'refreshes the TTL up to EXCEEDANCE_CACHE_TTL on read', :aggregate_failures do
          exceeded?

          raw_key = Gitlab::Cache::Import::Caching.cache_key_for(instance.send(:cache_key))

          # Shrink the TTL so the refresh-on-read is observable as a jump back up to the short window.
          Gitlab::Redis::SharedState.with { |redis| redis.expire(raw_key, 5) }

          described_class.new(namespace: namespace).exceeded?

          ttl = Gitlab::Redis::SharedState.with { |redis| redis.ttl(raw_key) }
          expect(ttl).to be > 5
          expect(ttl).to be <= described_class::EXCEEDANCE_CACHE_TTL.to_i
        end
      end
    end
  end

  describe '#limit' do
    subject(:instance) { described_class.new(namespace: namespace) }

    context 'when plan has a limit' do
      let(:limit) { 2 }

      before do
        create(:plan_limits, plan: plan, import_placeholder_user_limit_tier_1: limit)
      end

      it { expect(instance.limit).to eq(limit) }

      it 'caches the result' do
        allow_next_instance_of(PlanLimits) do |plan_limit|
          expect(plan_limit).to receive(:limit_for).once.and_call_original
        end

        2.times { expect(described_class.new(namespace: namespace).limit).to eq(limit) }
      end

      it 'reads the cached limit without refreshing the TTL' do
        instance.limit

        expect(Gitlab::Cache::Import::Caching)
          .to receive(:read_integer)
          .with(instance.send(:limit_cache_key), refresh: false)
          .and_call_original

        described_class.new(namespace: namespace).limit
      end

      it 'does not slide the TTL forward on subsequent reads' do
        instance.limit

        raw_key = Gitlab::Cache::Import::Caching.cache_key_for(instance.send(:limit_cache_key))

        # Shrink the TTL so a refresh-on-read would be observable as a jump back up to the write TTL.
        Gitlab::Redis::SharedState.with { |redis| redis.expire(raw_key, 10) }

        3.times { described_class.new(namespace: namespace).limit }

        ttl = Gitlab::Redis::SharedState.with { |redis| redis.ttl(raw_key) }
        expect(ttl).to be <= 10
      end
    end

    context 'when plan has no limit (unlimited)' do
      it { expect(instance.limit).to eq(0) }

      it 'caches the result' do
        allow_next_instance_of(PlanLimits) do |plan_limit|
          expect(plan_limit).to receive(:limit_for).once.and_call_original
        end

        2.times { expect(described_class.new(namespace: namespace).limit).to eq(0) }
      end
    end
  end

  describe '#count' do
    let(:limit) { 2 }

    subject(:instance) { described_class.new(namespace: namespace) }

    before do
      allow(instance).to receive(:limit).and_return(limit)
    end

    it 'returns the count' do
      expect(Import::SourceUser).to receive(:namespace_placeholder_user_count).with(namespace, limit: limit)
                                                                              .and_call_original

      expect(instance.count).to eq(1)
    end
  end
end
