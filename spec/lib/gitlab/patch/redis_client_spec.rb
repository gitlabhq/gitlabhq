# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::RedisClient, feature_category: :redis do
  include RedisHelpers

  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be(:redis_store_class, freeze: false) { define_helper_redis_store_class }
  let_it_be(:redis_client, freeze: false) { RedisClient.new(redis_store_class.params) }

  before do
    Thread.current[:redis_client_error_count] = 1
  end

  it 'resets tracking count after each call' do
    expect { redis_client.call("ping") }
      .to change { Thread.current[:redis_client_error_count] }
      .from(1).to(0)
  end

  it 'resets tracking count after each blocking call' do
    expect { redis_client.blocking_call(false, "ping") }
      .to change { Thread.current[:redis_client_error_count] }
      .from(1).to(0)
  end

  it 'resets tracking count after pipelined' do
    expect { redis_client.pipelined { |p| p.call("ping") } }
      .to change { Thread.current[:redis_client_error_count] }
      .from(1).to(0)
  end

  it 'resets tracking count after multi' do
    expect { redis_client.multi { |p| p.call("ping") } }
      .to change { Thread.current[:redis_client_error_count] }
      .from(1).to(0)
  end
end
