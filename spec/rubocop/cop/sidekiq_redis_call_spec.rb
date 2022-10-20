# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../rubocop/cop/sidekiq_redis_call'

RSpec.describe RuboCop::Cop::SidekiqRedisCall do
  it 'flags any use of Sidekiq.redis even without blocks' do
    expect_offense(<<~PATTERN)
      Sidekiq.redis
      ^^^^^^^^^^^^^ Refrain from directly using Sidekiq.redis unless for migration. For admin operations, use Sidekiq APIs.
    PATTERN
  end

  it 'flags the use of Sidekiq.redis in single-line blocks' do
    expect_offense(<<~PATTERN)
      Sidekiq.redis { |redis| yield redis }
      ^^^^^^^^^^^^^ Refrain from directly using Sidekiq.redis unless for migration. For admin operations, use Sidekiq APIs.
    PATTERN
  end

  it 'flags the use of Sidekiq.redis in multi-line blocks' do
    expect_offense(<<~PATTERN)
      Sidekiq.redis do |conn|
      ^^^^^^^^^^^^^ Refrain from directly using Sidekiq.redis unless for migration. For admin operations, use Sidekiq APIs.
        conn.sadd('queues', queues)
      end
    PATTERN
  end
end
