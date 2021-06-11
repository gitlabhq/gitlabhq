# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetJobWaiterTtl, :redis do
  it 'sets TTLs where necessary' do
    waiter_with_ttl = Gitlab::JobWaiter.new.key
    waiter_without_ttl = Gitlab::JobWaiter.new.key
    key_with_ttl = "foo:bar"
    key_without_ttl = "foo:qux"

    Gitlab::Redis::SharedState.with do |redis|
      redis.set(waiter_with_ttl, "zzz", ex: 2000)
      redis.set(waiter_without_ttl, "zzz")
      redis.set(key_with_ttl, "zzz", ex: 2000)
      redis.set(key_without_ttl, "zzz")

      described_class.new.up

      # This is the point of the migration. We know the migration uses a TTL of 21_600
      expect(redis.ttl(waiter_without_ttl)).to be > 20_000

      # Other TTL's should be untouched by the migration
      expect(redis.ttl(waiter_with_ttl)).to be_between(1000, 2000)
      expect(redis.ttl(key_with_ttl)).to be_between(1000, 2000)
      expect(redis.ttl(key_without_ttl)).to eq(-1)
    end
  end
end
