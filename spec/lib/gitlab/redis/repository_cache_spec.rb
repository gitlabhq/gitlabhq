# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::RepositoryCache, feature_category: :scalability do
  include_examples "redis_new_instance_shared_examples", 'repository_cache', Gitlab::Redis::Cache

  describe '#raw_config_hash' do
    it 'has a legacy default URL' do
      expect(subject).to receive(:fetch_config).and_return(false)

      expect(subject.send(:raw_config_hash)).to eq(url: 'redis://localhost:6380')
    end
  end

  describe '.cache_store' do
    it 'has a default ttl of 8 hours' do
      expect(described_class.cache_store.options[:expires_in]).to eq(8.hours)
    end
  end
end
