# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Cache, feature_category: :shared do
  let(:instance_specific_config_file) { "config/redis.cache.yml" }

  include_examples "redis_shared_examples"

  describe '.active_support_config' do
    it 'has a default ttl of 8 hours' do
      expect(described_class.active_support_config[:expires_in]).to eq(8.hours)
    end

    it 'allows configuring the TTL through an env variable' do
      stub_env('GITLAB_RAILS_CACHE_DEFAULT_TTL_SECONDS' => '86400')

      expect(described_class.active_support_config[:expires_in]).to eq(1.day)
    end

    it 'has a pool set to false' do
      expect(described_class.active_support_config[:pool]).to eq(false)
    end
  end
end
