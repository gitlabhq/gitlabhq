# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Cache do
  let(:instance_specific_config_file) { "config/redis.cache.yml" }
  let(:environment_config_file_name) { "GITLAB_REDIS_CACHE_CONFIG_FILE" }

  include_examples "redis_shared_examples"

  describe '#raw_config_hash' do
    it 'has a legacy default URL' do
      expect(subject).to receive(:fetch_config) { false }

      expect(subject.send(:raw_config_hash)).to eq(url: 'redis://localhost:6380' )
    end
  end

  describe '.active_support_config' do
    it 'has a default ttl of 8 hours' do
      expect(described_class.active_support_config[:expires_in]).to eq(8.hours)
    end

    it 'allows configuring the TTL through an env variable' do
      stub_env('GITLAB_RAILS_CACHE_DEFAULT_TTL_SECONDS' => '86400')

      expect(described_class.active_support_config[:expires_in]).to eq(1.day)
    end
  end
end
