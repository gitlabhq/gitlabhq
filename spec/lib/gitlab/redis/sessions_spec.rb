# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Sessions do
  it_behaves_like "redis_new_instance_shared_examples", 'sessions', Gitlab::Redis::SharedState

  describe 'redis instance used in connection pool' do
    before do
      clear_pool
    end

    after do
      clear_pool
    end

    context 'when redis.sessions configuration is not provided' do
      it 'uses ::Redis instance' do
        expect(described_class).to receive(:config_fallback?).and_return(true)

        described_class.pool.with do |redis_instance|
          expect(redis_instance).to be_instance_of(::Redis)
        end
      end
    end

    context 'when redis.sessions configuration is provided' do
      it 'instantiates an instance of MultiStore' do
        expect(described_class).to receive(:config_fallback?).and_return(false)

        described_class.pool.with do |redis_instance|
          expect(redis_instance).to be_instance_of(::Gitlab::Redis::MultiStore)
        end
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

    context 'when redis.sessions configuration is NOT provided' do
      it 'instantiates ::Redis instance' do
        expect(described_class).to receive(:config_fallback?).and_return(true)
        expect(store).to be_instance_of(::Redis::Store)
      end
    end

    context 'when redis.sessions configuration is provided' do
      let(:config_new_format_host) { "spec/fixtures/config/redis_new_format_host.yml" }
      let(:config_new_format_socket) { "spec/fixtures/config/redis_new_format_socket.yml" }

      before do
        redis_clear_raw_config!(Gitlab::Redis::Sessions)
        redis_clear_raw_config!(Gitlab::Redis::SharedState)
        allow(described_class).to receive(:config_fallback?).and_return(false)
      end

      after do
        redis_clear_raw_config!(Gitlab::Redis::Sessions)
        redis_clear_raw_config!(Gitlab::Redis::SharedState)
      end

      # Check that Gitlab::Redis::Sessions is configured as MultiStore with proper attrs.
      it 'instantiates an instance of MultiStore', :aggregate_failures do
        expect(described_class).to receive(:config_file_name).and_return(config_new_format_host)
        expect(::Gitlab::Redis::SharedState).to receive(:config_file_name).and_return(config_new_format_socket)

        expect(store).to be_instance_of(::Gitlab::Redis::MultiStore)

        expect(store.primary_store.to_s).to eq("Redis Client connected to test-host:6379 against DB 99 with namespace session:gitlab")
        expect(store.secondary_store.to_s).to eq("Redis Client connected to /path/to/redis.sock against DB 0 with namespace session:gitlab")

        expect(store.instance_name).to eq('Sessions')
      end

      context 'when MultiStore correctly configured' do
        before do
          allow(described_class).to receive(:config_file_name).and_return(config_new_format_host)
          allow(::Gitlab::Redis::SharedState).to receive(:config_file_name).and_return(config_new_format_socket)
        end

        it_behaves_like 'multi store feature flags', :use_primary_and_secondary_stores_for_sessions, :use_primary_store_as_default_for_sessions
      end
    end
  end
end
