# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::RepositoryCache, feature_category: :scalability do
  include_examples "redis_new_instance_shared_examples", 'repository_cache', Gitlab::Redis::Cache
  include_examples "redis_shared_examples"

  describe '#pool' do
    let(:config_new_format_host) { "spec/fixtures/config/redis_new_format_host.yml" }
    let(:config_new_format_socket) { "spec/fixtures/config/redis_new_format_socket.yml" }

    subject { described_class.pool }

    before do
      allow(described_class).to receive(:config_file_name).and_return(config_new_format_host)
      allow(Gitlab::Redis::Cache).to receive(:config_file_name).and_return(config_new_format_socket)
    end

    around do |example|
      clear_pool
      example.run
    ensure
      clear_pool
    end

    it 'instantiates an instance of MultiStore' do
      subject.with do |redis_instance|
        expect(redis_instance).to be_instance_of(::Gitlab::Redis::MultiStore)

        expect(redis_instance.primary_store.connection[:id]).to eq("redis://test-host:6379/99")
        expect(redis_instance.secondary_store.connection[:id]).to eq("unix:///path/to/redis.sock/0")

        expect(redis_instance.instance_name).to eq('RepositoryCache')
      end
    end

    it_behaves_like 'multi store feature flags', :use_primary_and_secondary_stores_for_repository_cache,
                    :use_primary_store_as_default_for_repository_cache
  end

  describe '#raw_config_hash' do
    it 'has a legacy default URL' do
      expect(subject).to receive(:fetch_config).and_return(false)

      expect(subject.send(:raw_config_hash)).to eq(url: 'redis://localhost:6380')
    end
  end
end
