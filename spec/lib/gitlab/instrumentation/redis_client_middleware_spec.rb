# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'
require 'support/helpers/rails_helpers'

RSpec.describe Gitlab::Instrumentation::RedisClientMiddleware, :request_store, feature_category: :scalability do
  using RSpec::Parameterized::TableSyntax
  include RedisHelpers

  let_it_be(:redis_store_class) { define_helper_redis_store_class }
  let_it_be(:redis_client) { RedisClient.new(redis_store_class.redis_client_params) }

  before do
    redis_client.call("flushdb")
  end

  describe 'read and write' do
    where(:setup, :command, :expect_write, :expect_read) do
      # The response is 'OK', the request size is the combined size of array
      # elements. Exercise counting of a status reply.
      [] | [:set, 'foo', 'bar'] | (3 + 3 + 3) | 2

      # The response is 1001, so 4 bytes. Exercise counting an integer reply.
      [[:set, 'foobar', 1000]] | [:incr, 'foobar'] | (4 + 6) | 4

      # Exercise counting empty multi bulk reply. Returns an empty hash `{}`
      [] | [:hgetall, 'foobar'] | (7 + 6) | 2

      # Hgetall response length is combined length of keys and values in the
      # hash. Exercises counting of a multi bulk reply
      # Returns `{"field"=>"hello world"}`, 5 for field, 11 for hello world, 8 for {, }, 4 "s, =, >
      [[:hset, 'myhash', 'field', 'hello world']] | [:hgetall, 'myhash'] | (7 + 6) | (5 + 11 + 8)

      # Exercise counting of a bulk reply
      [[:set, 'foo', 'bar' * 100]] | [:get, 'foo'] | (3 + 3) | (3 * 100)

      # Nested array response: [['foo', 0.0], ['bar', 1.0]]. Returns scores as float.
      [[:zadd, 'myset', 0, 'foo'],
        [:zadd, 'myset', 1, 'bar']] | [:zrange, 'myset', 0, -1, 'withscores'] | (6 + 5 + 1 + 2 + 10) | (3 + 3 + 3 + 3)
    end

    with_them do
      it 'counts bytes read and written' do
        setup.each { |cmd| redis_client.call(*cmd) }
        RequestStore.clear!
        redis_client.call(*command)

        expect(Gitlab::Instrumentation::Redis.read_bytes).to eq(expect_read)
        expect(Gitlab::Instrumentation::Redis.write_bytes).to eq(expect_write)
      end
    end
  end

  describe 'counting' do
    let(:instrumentation_class) { redis_store_class.instrumentation_class }

    it 'counts successful requests' do
      expect(instrumentation_class).to receive(:instance_count_request).with(1).and_call_original

      redis_client.call(:get, 'foobar')
    end

    it 'counts successful pipelined requests' do
      expect(instrumentation_class).to receive(:instance_count_request).with(2).and_call_original
      expect(instrumentation_class).to receive(:instance_count_pipelined_request).with(2).and_call_original

      redis_client.pipelined do |pipeline|
        pipeline.call(:get, '{foobar}buz')
        pipeline.call(:get, '{foobar}baz')
      end
    end

    context 'when encountering exceptions' do
      before do
        allow(redis_client.instance_variable_get(:@raw_connection)).to receive(:call).and_raise(
          RedisClient::Error)
      end

      it 'counts exception' do
        expect(instrumentation_class).to receive(:instance_count_exception)
                                           .with(instance_of(RedisClient::Error)).and_call_original
        expect(instrumentation_class).to receive(:log_exception)
                                           .with(instance_of(RedisClient::Error)).and_call_original
        expect(instrumentation_class).to receive(:instance_count_request).and_call_original

        expect do
          redis_client.call(:auth, 'foo', 'bar')
        end.to raise_error(RedisClient::Error)
      end
    end

    context 'in production environment' do
      before do
        stub_rails_env('production') # to avoid raising CrossSlotError
      end

      it 'counts disallowed cross-slot requests' do
        expect(instrumentation_class).to receive(:increment_cross_slot_request_count).and_call_original
        expect(instrumentation_class).not_to receive(:increment_allowed_cross_slot_request_count).and_call_original

        redis_client.call(:mget, 'foo', 'bar')
      end

      it 'does not count allowed cross-slot requests' do
        expect(instrumentation_class).not_to receive(:increment_cross_slot_request_count).and_call_original
        expect(instrumentation_class).to receive(:increment_allowed_cross_slot_request_count).and_call_original

        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          redis_client.call(:mget, 'foo', 'bar')
        end
      end

      it 'does not count allowed non-cross-slot requests' do
        expect(instrumentation_class).not_to receive(:increment_cross_slot_request_count).and_call_original
        expect(instrumentation_class).not_to receive(:increment_allowed_cross_slot_request_count).and_call_original

        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          redis_client.call(:mget, 'bar')
        end
      end

      it 'skips count for non-cross-slot requests' do
        expect(instrumentation_class).not_to receive(:increment_cross_slot_request_count).and_call_original
        expect(instrumentation_class).not_to receive(:increment_allowed_cross_slot_request_count).and_call_original

        redis_client.call(:mget, '{foo}bar', '{foo}baz')
      end
    end

    context 'without active RequestStore' do
      before do
        ::RequestStore.end!
      end

      it 'still runs cross-slot validation' do
        expect do
          redis_client.call('mget', 'foo', 'bar')
        end.to raise_error(instance_of(Gitlab::Instrumentation::RedisClusterValidator::CrossSlotError))
      end
    end
  end

  describe 'latency' do
    let(:instrumentation_class) { redis_store_class.instrumentation_class }

    describe 'commands in the apdex' do
      where(:command) do
        [
          [[:get, 'foobar']],
          [%w[GET foobar]]
        ]
      end

      with_them do
        it 'measures requests we want in the apdex' do
          expect(instrumentation_class).to receive(:instance_observe_duration).with(a_value > 0)
            .and_call_original

          redis_client.call(*command)
        end
      end

      context 'with pipelined commands' do
        it 'measures requests that do not have blocking commands' do
          expect(instrumentation_class).to receive(:instance_observe_duration).twice.with(a_value > 0)
            .and_call_original

          redis_client.pipelined do |pipeline|
            pipeline.call(:get, '{foobar}buz')
            pipeline.call(:get, '{foobar}baz')
          end
        end

        it 'raises error when keys are not from the same slot' do
          expect do
            redis_client.pipelined do |pipeline|
              pipeline.call(:get, 'foo')
              pipeline.call(:get, 'bar')
            end
          end.to raise_error(instance_of(Gitlab::Instrumentation::RedisClusterValidator::CrossSlotError))
        end
      end
    end

    describe 'commands not in the apdex' do
      where(:setup, :command) do
        [['rpush', 'foobar', 1]] | ['brpop', 'foobar', 0]
        [['rpush', 'foobar', 1]] | ['blpop', 'foobar', 0]
        [['rpush', '{abc}foobar', 1]] | ['brpoplpush', '{abc}foobar', '{abc}bazqux', 0]
        [['rpush', '{abc}foobar', 1]] | ['brpoplpush', '{abc}foobar', '{abc}bazqux', 0]
        [['zadd', 'foobar', 1, 'a']] | ['bzpopmin', 'foobar', 0]
        [['zadd', 'foobar', 1, 'a']] | ['bzpopmax', 'foobar', 0]
        [['xadd', 'mystream', 1, 'myfield', 'mydata']] | ['xread', 'block', 1, 'streams', 'mystream', '0-0']
        [['xadd', 'foobar', 1, 'myfield', 'mydata'],
          ['xgroup', 'create', 'foobar', 'mygroup',
            0]] | ['xreadgroup', 'group', 'mygroup', 'myconsumer', 'block', 1, 'streams', 'foobar', '0-0']
        [] | ['command']
      end

      with_them do
        it 'skips requests we do not want in the apdex' do
          setup.each { |cmd| redis_client.call(*cmd) }

          expect(instrumentation_class).not_to receive(:instance_observe_duration)

          redis_client.call(*command)
        end
      end

      context 'with pipelined commands' do
        it 'skips requests that have blocking commands' do
          expect(instrumentation_class).not_to receive(:instance_observe_duration)

          redis_client.pipelined do |pipeline|
            pipeline.call(:get, '{foobar}buz')
            pipeline.call(:rpush, '{foobar}baz', 1)
            pipeline.call(:brpop, '{foobar}baz', 0)
          end
        end
      end
    end
  end
end
