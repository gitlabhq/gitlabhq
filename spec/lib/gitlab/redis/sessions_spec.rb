# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Sessions do
  it_behaves_like "redis_new_instance_shared_examples", 'sessions', Gitlab::Redis::SharedState

  describe 'redis instance used in connection pool' do
    around do |example|
      clear_pool
      example.run
    ensure
      clear_pool
    end

    it 'uses ::Redis instance' do
      described_class.pool.with do |redis_instance|
        expect(redis_instance).to be_instance_of(::Redis)
      end
    end

    def clear_pool
      described_class.remove_instance_variable(:@pool)
    rescue NameError
      # raised if @pool was not set; ignore
    end
  end

  describe '#store' do
    subject(:store) { described_class.store(namespace: described_class::SESSION_NAMESPACE) }

    # Check that Gitlab::Redis::Sessions is configured as RedisStore.
    it 'instantiates an instance of Redis::Store' do
      expect(store).to be_instance_of(::Redis::Store)
    end
  end
end
