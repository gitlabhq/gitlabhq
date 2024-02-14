# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Sessions do
  it_behaves_like "redis_new_instance_shared_examples", 'sessions', Gitlab::Redis::SharedState

  describe '#store' do
    subject(:store) { described_class.store(namespace: described_class::SESSION_NAMESPACE) }

    # Check that Gitlab::Redis::Sessions is configured as RedisStore.
    it 'instantiates an instance of Redis::Store' do
      expect(store).to be_instance_of(::Redis::Store)
    end
  end
end
