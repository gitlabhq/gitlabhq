# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::Instrumentation::RedisInterceptor, :clean_gitlab_redis_shared_state, :request_store do
  using RSpec::Parameterized::TableSyntax

  describe 'read and write' do
    where(:setup, :command, :expect_write, :expect_read) do
      # The response is 'OK', the request size is the combined size of array
      # elements. Exercise counting of a status reply.
      [] | [:set, 'foo', 'bar'] | 3 + 3 + 3 | 2

      # The response is 1001, so 4 bytes. Exercise counting an integer reply.
      [[:set, 'foobar', 1000]] | [:incr, 'foobar'] | 4 + 6 | 4

      # Exercise counting empty multi bulk reply
      [] | [:hgetall, 'foobar'] | 7 + 6 | 0

      # Hgetall response length is combined length of keys and values in the
      # hash. Exercises counting of a multi bulk reply
      [[:hset, 'myhash', 'field', 'hello world']] | [:hgetall, 'myhash'] | 7 + 6 | 5 + 11

      # Exercise counting of a bulk reply
      [[:set, 'foo', 'bar' * 100]] | [:get, 'foo'] | 3 + 3 | 3 * 100

      # Nested array response: [['foo', 0], ['bar', 1]]
      [[:zadd, 'myset', 0, 'foo'], [:zadd, 'myset', 1, 'bar']] | [:zrange, 'myset', 0, -1, 'withscores'] | 6 + 5 + 1 + 2 + 10 | 3 + 1 + 3 + 1
    end

    with_them do
      it 'counts bytes read and written' do
        Gitlab::Redis::SharedState.with do |redis|
          setup.each { |cmd| redis.call(cmd) }
          RequestStore.clear!
          redis.call(command)
        end

        expect(Gitlab::Instrumentation::Redis.read_bytes).to eq(expect_read)
        expect(Gitlab::Instrumentation::Redis.write_bytes).to eq(expect_write)
      end
    end
  end

  describe 'counting' do
    let(:instrumentation_class) { Gitlab::Redis::SharedState.instrumentation_class }

    it 'counts successful requests' do
      expect(instrumentation_class).to receive(:instance_count_request).and_call_original

      Gitlab::Redis::SharedState.with { |redis| redis.call(:get, 'foobar') }
    end

    it 'counts exceptions' do
      expect(instrumentation_class).to receive(:instance_count_exception)
        .with(instance_of(Redis::CommandError)).and_call_original
      expect(instrumentation_class).to receive(:instance_count_request).and_call_original

      expect do
        Gitlab::Redis::SharedState.with do |redis|
          redis.call(:auth, 'foo', 'bar')
        end
      end.to raise_exception(Redis::CommandError)
    end
  end

  describe 'latency' do
    let(:instrumentation_class) { Gitlab::Redis::SharedState.instrumentation_class }

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

          Gitlab::Redis::SharedState.with { |redis| redis.call(*command) }
        end
      end
    end

    describe 'commands not in the apdex' do
      where(:command) do
        [
          [%w[brpop foobar 0.01]],
          [%w[blpop foobar 0.01]],
          [%w[brpoplpush foobar bazqux 0.01]],
          [%w[bzpopmin foobar 0.01]],
          [%w[bzpopmax foobar 0.01]],
          [%w[xread block 1 streams mystream 0-0]],
          [%w[xreadgroup group mygroup myconsumer block 1 streams foobar 0-0]]
        ]
      end

      with_them do
        it 'skips requests we do not want in the apdex' do
          expect(instrumentation_class).not_to receive(:instance_observe_duration)

          begin
            Gitlab::Redis::SharedState.with { |redis| redis.call(*command) }
          rescue Gitlab::Instrumentation::RedisClusterValidator::CrossSlotError, ::Redis::CommandError
          end
        end
      end
    end
  end

  context 'when a command takes longer than DURATION_ERROR_THRESHOLD' do
    let(:threshold) { 0.5 }

    before do
      stub_const("#{described_class}::DURATION_ERROR_THRESHOLD", threshold)
    end

    context 'when report_on_long_redis_durations is disabled' do
      it 'does nothing' do
        stub_feature_flags(report_on_long_redis_durations: false)

        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        Gitlab::Redis::SharedState.with { |r| r.mget('foo', 'foo') { sleep threshold + 0.1 } }
      end
    end

    context 'when report_on_long_redis_durations is enabled' do
      it 'tracks an exception and continues' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
                .with(an_instance_of(described_class::MysteryRedisDurationError),
                      command: 'mget',
                      duration: be > threshold,
                      timestamp: a_string_matching(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{5}/))

        Gitlab::Redis::SharedState.with { |r| r.mget('foo', 'foo') { sleep threshold + 0.1 } }
      end
    end
  end
end
