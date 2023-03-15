# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::RateLimiting do
  include_examples "redis_new_instance_shared_examples", 'rate_limiting', Gitlab::Redis::Cache

  describe '.cache_store' do
    it 'uses the CACHE_NAMESPACE namespace' do
      expect(described_class.cache_store.options[:namespace]).to eq(Gitlab::Redis::Cache::CACHE_NAMESPACE)
    end
  end
end
