# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::FeatureFlag, feature_category: :redis do
  include_examples "redis_new_instance_shared_examples", 'feature_flag', Gitlab::Redis::Cache

  describe '.cache_store' do
    it 'has a default ttl of 1 hour' do
      expect(described_class.cache_store.options[:expires_in]).to eq(1.hour)
    end

    it 'has Rails61CoderBackwardsCompatible as the cache coder' do
      expect(described_class.cache_store.instance_variable_get(:@coder))
        .to be(Gitlab::Redis::Rails61CoderBackwardsCompatible)
    end
  end
end
