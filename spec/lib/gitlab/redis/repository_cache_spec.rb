# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::RepositoryCache, feature_category: :scalability do
  include_examples "redis_new_instance_shared_examples", 'repository_cache', Gitlab::Redis::Cache

  describe '.cache_store' do
    it 'has a default ttl of 8 hours' do
      expect(described_class.cache_store.options[:expires_in]).to eq(8.hours)
    end

    it 'has Rails61CoderBackwardsCompatible as the cache coder' do
      expect(described_class.cache_store.instance_variable_get(:@coder))
        .to be(Gitlab::Redis::Rails61CoderBackwardsCompatible)
    end
  end
end
