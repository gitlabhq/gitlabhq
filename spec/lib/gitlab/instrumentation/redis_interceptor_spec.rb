# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

describe Gitlab::Instrumentation::RedisInterceptor, :clean_gitlab_redis_shared_state, :request_store do
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
end
