# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::CrossSlot, feature_category: :redis do
  include RedisHelpers

  let_it_be(:redis_store_class) { define_helper_redis_store_class }

  before do
    redis_store_class.with(&:flushdb)
  end

  describe '.pipelined' do
    context 'when using redis client' do
      before do
        redis_store_class.with { |redis| redis.set('a', 1) }
      end

      it 'performs redis-rb pipelined' do
        expect(Gitlab::Redis::CrossSlot::Router).not_to receive(:new)

        expect(
          Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
            redis_store_class.with do |redis|
              described_class::Pipeline.new(redis).pipelined do |p|
                p.get('a')
                p.set('b', 1)
              end
            end
          end
        ).to eq(%w[1 OK])
      end
    end

    context 'when using with MultiStore' do
      let_it_be(:primary_db) { 1 }
      let_it_be(:secondary_db) { 2 }
      let_it_be(:primary_store) { create_redis_store(redis_store_class.params, db: primary_db, serializer: nil) }
      let_it_be(:secondary_store) { create_redis_store(redis_store_class.params, db: secondary_db, serializer: nil) }
      let_it_be(:multistore) { Gitlab::Redis::MultiStore.new(primary_store, secondary_store, 'testing') }

      before do
        primary_store.set('a', 1)
        secondary_store.set('a', 1)
        skip_feature_flags_yaml_validation
        skip_default_enabled_yaml_check
      end

      it 'performs multistore pipelined' do
        expect(Gitlab::Redis::CrossSlot::Router).not_to receive(:new)

        expect(
          Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
            described_class::Pipeline.new(multistore).pipelined do |p|
              p.get('a')
              p.set('b', 1)
            end
          end
        ).to eq(%w[1 OK])
      end
    end

    context 'when using Redis::Cluster' do
      # Only stub redis client internals since the CI pipeline does not run a Redis Cluster
      let(:redis) { double(:redis) } # rubocop:disable RSpec/VerifiedDoubles
      let(:client) { double(:client) } # rubocop:disable RSpec/VerifiedDoubles
      let(:pipeline) { double(:pipeline) } # rubocop:disable RSpec/VerifiedDoubles

      let(:arguments) { %w[a b c d] }

      subject do
        described_class::Pipeline.new(redis).pipelined do |p|
          arguments.each { |key| p.get(key) }
        end
      end

      before do
        allow(redis).to receive(:_client).and_return(client)
        allow(redis).to receive(:pipelined).and_yield(pipeline)
        allow(client).to receive(:instance_of?).with(::Redis::Cluster).and_return(true)
      end

      it 'fan-out and fan-in commands to separate shards' do
        # simulate fan-out to 3 shards with random order
        expect(client).to receive(:_find_node_key).exactly(4).times.and_return(3, 2, 1, 3)

        arguments.each do |key|
          f = double('future') # rubocop:disable RSpec/VerifiedDoubles
          expect(pipeline).to receive(:get).with(key).and_return(f)
          expect(f).to receive(:value).and_return(key)
        end

        expect(subject).to eq(arguments)
      end

      shared_examples 'fallback on cross-slot' do |redirection|
        context 'when redis cluster undergoing slot migration' do
          before do
            allow(pipeline).to receive(:get).and_raise(::Redis::CommandError.new("#{redirection} 1 127.0.0.1:7001"))
          end

          it 'logs error and executes sequentially' do
            expect(client).to receive(:_find_node_key).exactly(4).times.and_return(3, 2, 1, 3)
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(::Redis::CommandError))

            arguments.each do |key|
              expect(redis).to receive(:get).with(key).and_return(key)
            end

            subject
          end
        end
      end

      it_behaves_like 'fallback on cross-slot', 'MOVED'
      it_behaves_like 'fallback on cross-slot', 'ASK'

      context 'when receiving non-MOVED/ASK command errors' do
        before do
          allow(pipeline).to receive(:get).and_raise(::Redis::CommandError.new)
          allow(client).to receive(:_find_node_key).exactly(4).times.and_return(3, 2, 1, 3)
        end

        it 'raises error' do
          expect { subject }.to raise_error(::Redis::CommandError)
        end
      end
    end
  end
end
