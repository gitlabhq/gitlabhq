# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Queues do
  include TmpdirHelper

  let(:instance_specific_config_file) { "config/redis.queues.yml" }

  include_examples "redis_shared_examples"

  describe '#raw_config_hash' do
    before do
      expect(subject).to receive(:fetch_config) { config }
    end

    context 'when the config url is present' do
      let(:config) { { url: 'redis://localhost:1111' } }

      it 'sets the configured url' do
        expect(subject.send(:raw_config_hash)).to eq(url: 'redis://localhost:1111')
      end
    end
  end

  describe '.shard_name' do
    it 'defaults to main' do
      expect(described_class.shard_name).to eq(described_class::SIDEKIQ_MAIN_SHARD_INSTANCE_NAME)
    end
  end

  describe '.sidekiq_redis' do
    subject(:sidekiq_redis) { described_class.sidekiq_redis }

    before do
      if described_class.instance_variable_defined?(:@sidekiq_redis)
        described_class.remove_instance_variable(:@sidekiq_redis)
      end
    end

    it 'returns a connection pool of sidekiq adapter clients' do
      expect(Sidekiq::RedisConnection).to receive(:create).and_call_original

      expect(sidekiq_redis.checkout).to be_an_instance_of(Sidekiq::RedisClientAdapter::CompatClient)
    end

    it 'memoizes sidekiq_redis in an instance variable' do
      expect(Sidekiq::RedisConnection).to receive(:create).once.and_call_original

      sidekiq_redis
      sidekiq_redis
    end
  end

  describe '.instances' do
    let(:rails_root) { mktmpdir }

    before do
      allow(described_class).to receive(:rails_root).and_return(rails_root)
      described_class.remove_instance_variable(:@instances) if described_class.instance_variable_defined?(:@instances)
    end

    after do
      described_class.remove_instance_variable(:@instances) if described_class.instance_variable_defined?(:@instances)
    end

    shared_examples 'no extra shards' do
      it 'returns a single map of self' do
        expect(described_class.instances).to eq({ 'main' => described_class })
      end
    end

    context 'when redis.yml is absent' do
      it_behaves_like 'no extra shards'
    end

    context 'when redis.yml is empty' do
      before do
        FileUtils.mkdir_p(File.join(rails_root, 'config'))
        FileUtils.touch(File.join(rails_root, 'config/redis.yml'))
      end

      it_behaves_like 'no extra shards'
    end

    context 'when redis.yml does not have required env' do
      before do
        FileUtils.mkdir_p(File.join(rails_root, 'config'))
        File.write(File.join(rails_root, 'config/redis.yml'), {
          'staging' => { 'queues_shard_1' => { 'foobar' => 123 } }
        }.to_json)
      end

      it_behaves_like 'no extra shards'
    end

    context 'when redis.yml does not correctly formatted data' do
      before do
        FileUtils.mkdir_p(File.join(rails_root, 'config'))
        File.write(File.join(rails_root, 'config/redis.yml'), {
          'test' => 'redis://redis:6379'
        }.to_json)
      end

      it_behaves_like 'no extra shards'
    end

    context 'when redis.yml does not contain any shard data' do
      before do
        FileUtils.mkdir_p(File.join(rails_root, 'config'))
        File.write(File.join(rails_root, 'config/redis.yml'), {
          'test' => { 'cache' => { 'foobar' => 123 } }
        }.to_json)
      end

      it_behaves_like 'no extra shards'
    end

    context 'when redis.yml contains shard data' do
      before do
        Gitlab::Instrumentation::Redis.const_set(:QueuesShardCatchall, 'dummy')
        FileUtils.mkdir_p(File.join(rails_root, 'config'))
        File.write(File.join(rails_root, 'config/redis.yml'), {
          'test' => { 'queues_shard_catchall' => { 'url' => 'redis://localhost:6379' } }
        }.to_json)
      end

      it 'returns extra wrapper classes for queue shards' do
        expect(described_class.instances).to eq(
          { 'main' => described_class, "queues_shard_catchall" => Gitlab::Redis::QueuesShardCatchall })
      end

      it 'extra wrapper classes implement new methods and overrides' do
        expect(described_class.instances["queues_shard_catchall"].ancestors).to include(Gitlab::Redis::Wrapper)
        expect(described_class.instances["queues_shard_catchall"].store_name).to eq("QueuesShardCatchall")
        expect(described_class.instances["queues_shard_catchall"].shard_name).to eq("queues_shard_catchall")
        expect(described_class.instances["queues_shard_catchall"].pool.checkout).to be_an_instance_of(Redis)
        expect(
          described_class.instances["queues_shard_catchall"].sidekiq_redis.checkout
        ).to be_an_instance_of(Sidekiq::RedisClientAdapter::CompatClient)
      end
    end
  end
end
