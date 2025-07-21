# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../rubocop/cop/redis_queue_usage'

RSpec.describe RuboCop::Cop::RedisQueueUsage do
  let(:msg) { described_class::MSG }

  context 'when assigning Gitlab::Redis::Queues as a variable' do
    it 'registers offence for any variable assignment' do
      expect_offense(<<~RUBY)
        x = Gitlab::Redis::Queues
        ^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offence for constant assignment' do
      expect_offense(<<~RUBY)
        X = Gitlab::Redis::Queues
        ^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end
  end

  context 'when assigning Gitlab::Redis::Queues as a part of an array' do
    it 'registers offence for variable assignments' do
      expect_offense(<<~RUBY)
        x = [ Gitlab::Redis::Cache, Gitlab::Redis::Queues, Gitlab::Redis::SharedState ]
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offence for constant assignments' do
      expect_offense(<<~RUBY)
        ALL = [ Gitlab::Redis::Cache, Gitlab::Redis::Queues, Gitlab::Redis::SharedState ]
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offence for constant assignments while invoking function' do
      expect_offense(<<~RUBY)
        ALL = [ Gitlab::Redis::Cache, Gitlab::Redis::Queues, Gitlab::Redis::SharedState ].freeze
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offence for constant assignments while invoking multiple functions' do
      expect_offense(<<~RUBY)
        ALL = [ Gitlab::Redis::Cache, Gitlab::Redis::Queues, Gitlab::Redis::SharedState ].foo.freeze
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end
  end

  context 'when assigning Gitlab::Redis::Queues as a part of a hash' do
    it 'registers offence for variable assignments' do
      expect_offense(<<~RUBY)
        x = { "test": Gitlab::Redis::Queues, "test2": Gitlab::Redis::SharedState }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offence for constant assignments' do
      expect_offense(<<~RUBY)
        ALL = { "test": Gitlab::Redis::Queues, "test2": Gitlab::Redis::SharedState }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offence for constant assignments while invoking function' do
      expect_offense(<<~RUBY)
        ALL = { "test": Gitlab::Redis::Queues, "test2": Gitlab::Redis::SharedState }.freeze
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offence for constant assignments while invoking multiple functions' do
      expect_offense(<<~RUBY)
        ALL = { "test": Gitlab::Redis::Queues, "test2": Gitlab::Redis::SharedState }.foo.freeze
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end
  end

  it 'registers offence for any invocation of Gitlab::Redis::Queues methods' do
    expect_offense(<<~RUBY)
      Gitlab::Redis::Queues.params
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
    RUBY
  end

  it 'registers offence for using Gitlab::Redis::Queues as parameter in method calls' do
    expect_offense(<<~RUBY)
      use_redis(Gitlab::Redis::Queues)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
    RUBY
  end
end
