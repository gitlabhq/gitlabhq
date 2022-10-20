# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../rubocop/cop/redis_queue_usage'

RSpec.describe RuboCop::Cop::RedisQueueUsage do
  let(:msg) { described_class::MSG }

  context 'when assigning Gitlab::Redis::Queues as a variable' do
    it 'registers offence for any variable assignment' do
      expect_offense(<<~PATTERN)
        x = Gitlab::Redis::Queues
        ^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end

    it 'registers offence for constant assignment' do
      expect_offense(<<~PATTERN)
        X = Gitlab::Redis::Queues
        ^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end
  end

  context 'when assigning Gitlab::Redis::Queues as a part of an array' do
    it 'registers offence for variable assignments' do
      expect_offense(<<~PATTERN)
        x = [ Gitlab::Redis::Cache, Gitlab::Redis::Queues, Gitlab::Redis::SharedState ]
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end

    it 'registers offence for constant assignments' do
      expect_offense(<<~PATTERN)
        ALL = [ Gitlab::Redis::Cache, Gitlab::Redis::Queues, Gitlab::Redis::SharedState ]
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end

    it 'registers offence for constant assignments while invoking function' do
      expect_offense(<<~PATTERN)
        ALL = [ Gitlab::Redis::Cache, Gitlab::Redis::Queues, Gitlab::Redis::SharedState ].freeze
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end

    it 'registers offence for constant assignments while invoking multiple functions' do
      expect_offense(<<~PATTERN)
        ALL = [ Gitlab::Redis::Cache, Gitlab::Redis::Queues, Gitlab::Redis::SharedState ].foo.freeze
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end
  end

  context 'when assigning Gitlab::Redis::Queues as a part of a hash' do
    it 'registers offence for variable assignments' do
      expect_offense(<<~PATTERN)
        x = { "test": Gitlab::Redis::Queues, "test2": Gitlab::Redis::SharedState }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end

    it 'registers offence for constant assignments' do
      expect_offense(<<~PATTERN)
        ALL = { "test": Gitlab::Redis::Queues, "test2": Gitlab::Redis::SharedState }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end

    it 'registers offence for constant assignments while invoking function' do
      expect_offense(<<~PATTERN)
        ALL = { "test": Gitlab::Redis::Queues, "test2": Gitlab::Redis::SharedState }.freeze
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end

    it 'registers offence for constant assignments while invoking multiple functions' do
      expect_offense(<<~PATTERN)
        ALL = { "test": Gitlab::Redis::Queues, "test2": Gitlab::Redis::SharedState }.foo.freeze
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end
  end

  it 'registers offence for any invocation of Gitlab::Redis::Queues methods' do
    expect_offense(<<~PATTERN)
      Gitlab::Redis::Queues.params
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
    PATTERN
  end

  it 'registers offence for using Gitlab::Redis::Queues as parameter in method calls' do
    expect_offense(<<~PATTERN)
      use_redis(Gitlab::Redis::Queues)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
    PATTERN
  end
end
