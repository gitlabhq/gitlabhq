# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqSharding::Router, feature_category: :scalability do
  describe '#enabled?' do
    subject(:router_enabled) { described_class.enabled? }

    context 'when there is only 1 queue instance' do
      it { expect(router_enabled).to be_falsey }

      context 'with feature flag disabled' do
        before do
          stub_feature_flags(enable_sidekiq_shard_router: false)
        end

        it { expect(router_enabled).to be_falsey }
      end
    end

    context 'when there is only multiple queue instances' do
      before do
        allow(Gitlab::Redis::Queues)
          .to receive(:instances).and_return({ main: Gitlab::Redis::Queues, extra: Gitlab::Redis::Queues })
      end

      context 'with feature flag enabled' do
        it { expect(router_enabled).to be_truthy }
      end

      context 'with feature flag disabled' do
        before do
          stub_feature_flags(enable_sidekiq_shard_router: false)
        end

        it { expect(router_enabled).to be_falsey }
      end
    end
  end

  describe '#get_shard_instance' do
    context 'when shard name is invalid' do
      it 'returns main shard info' do
        name, redis = described_class.get_shard_instance(nil)

        expect(name).to eq('main')
        expect(redis).to eq(Gitlab::Redis::Queues.instances['main'].sidekiq_redis)
      end

      context 'when shard name is invalid' do
        before do
          # stub production env to avoid raising Feature::InvalidFeatureFlagError
          # the goal is to ensure that any random string will not crash the router at runtime
          stub_rails_env('production')
        end

        it 'returns main shard info' do
          name, redis = described_class.get_shard_instance('unknown')

          expect(name).to eq('main')
          expect(redis).to eq(Gitlab::Redis::Queues.instances['main'].sidekiq_redis)
        end
      end
    end

    context 'when shard name is valid' do
      let(:main_instance) { class_double("Gitlab::Redis::Queues") }
      let(:shard_instance) { class_double("Gitlab::Redis::Queues") }
      let(:main_sidekiq_redis) { 'main_dummy' }
      let(:shard_sidekiq_redis) { 'shard_dummy' }

      subject(:get_test_shard) { described_class.get_shard_instance('queues_shard_test') }

      before do
        # stubbing feature flag is ineffective since this feature flag definition does not exist
        allow(Feature).to receive(:enabled?)
          .with(:sidekiq_route_to_queues_shard_test, default_enabled_if_undefined: false, type: :worker)
          .and_return(false)

        allow(main_instance).to receive(:sidekiq_redis).and_return(main_sidekiq_redis)
        allow(shard_instance).to receive(:sidekiq_redis).and_return(shard_sidekiq_redis)
        allow(Gitlab::Redis::Queues).to receive(:instances).and_return({ 'main' => main_instance,
'queues_shard_test' => shard_instance })
      end

      context 'when feature flag is disabled' do
        it 'returns main' do
          name, redis = get_test_shard

          expect(name).to eq('main')
          expect(redis).to eq(main_sidekiq_redis)
        end
      end

      context 'when instance is nil due to mismatched configuration' do
        before do
          allow(Gitlab::Redis::Queues).to receive(:instances).and_return({ 'main' => main_instance,
  'queues_shard_test' => nil })
        end

        it 'still returns main' do
          name, redis = get_test_shard

          expect(name).to eq('main')
          expect(redis).to eq(main_sidekiq_redis)
        end
      end

      context 'when shard is migrated' do
        before do
          stub_env('SIDEKIQ_MIGRATED_SHARDS', "[\"queues_shard_test\"]")

          if described_class.instance_variable_defined?(:@migrated_shards)
            described_class.remove_instance_variable(:@migrated_shards)
          end
        end

        it 'returns shard without checking feature flag' do
          expect(Feature).not_to receive(:enabled?)

          name, redis = get_test_shard

          expect(name).to eq('queues_shard_test')
          expect(redis).to eq(shard_sidekiq_redis)
        end
      end

      context 'when feature flag is enabled' do
        before do
          allow(Feature).to receive(:enabled?)
            .with(:sidekiq_route_to_queues_shard_test, default_enabled_if_undefined: false, type: :worker)
            .and_return(true)
        end

        it 'returns the test shard info' do
          name, redis = get_test_shard

          expect(name).to eq('queues_shard_test')
          expect(redis).to eq(shard_sidekiq_redis)
        end
      end
    end
  end
end
