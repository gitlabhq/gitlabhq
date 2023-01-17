# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::DuplicateJobs do
  # Note: this is a pseudo-store in front of `SharedState`, meant only as a tool
  # to move away from `Sidekiq.redis` for duplicate job data. Thus, we use the
  # same store configuration as the former.
  let(:instance_specific_config_file) { "config/redis.shared_state.yml" }
  let(:environment_config_file_name) { "GITLAB_REDIS_SHARED_STATE_CONFIG_FILE" }

  include_examples "redis_shared_examples"

  describe '#pool' do
    subject { described_class.pool }

    around do |example|
      clear_pool
      example.run
    ensure
      clear_pool
    end

    context 'store connection settings' do
      let(:config_new_format_host) { "spec/fixtures/config/redis_new_format_host.yml" }
      let(:config_new_format_socket) { "spec/fixtures/config/redis_new_format_socket.yml" }

      before do
        allow(Gitlab::Redis::SharedState).to receive(:config_file_name).and_return(config_new_format_host)
        allow(Gitlab::Redis::Queues).to receive(:config_file_name).and_return(config_new_format_socket)
      end

      it 'instantiates an instance of MultiStore' do
        subject.with do |redis_instance|
          expect(redis_instance).to be_instance_of(::Gitlab::Redis::MultiStore)

          expect(redis_instance.primary_store.connection[:id]).to eq("redis://test-host:6379/99")
          expect(redis_instance.primary_store.connection[:namespace]).to be_nil
          expect(redis_instance.secondary_store.connection[:id]).to eq("unix:///path/to/redis.sock/0")
          expect(redis_instance.secondary_store.connection[:namespace]).to eq("resque:gitlab")

          expect(redis_instance.instance_name).to eq('DuplicateJobs')
        end
      end
    end

    # Make sure they current namespace is respected for the secondary store but omitted from the primary
    context 'key namespaces' do
      let(:key) { 'key' }
      let(:value) { '123' }

      it 'writes keys to SharedState with no prefix, and to Queues with the "resque:gitlab:" prefix' do
        subject.with do |redis_instance|
          redis_instance.set(key, value)
        end

        Gitlab::Redis::SharedState.with do |redis_instance|
          expect(redis_instance.get(key)).to eq(value)
        end

        Gitlab::Redis::Queues.with do |redis_instance|
          expect(redis_instance.get("resque:gitlab:#{key}")).to eq(value)
        end
      end
    end

    it_behaves_like 'multi store feature flags', :use_primary_and_secondary_stores_for_duplicate_jobs,
                                                 :use_primary_store_as_default_for_duplicate_jobs
  end

  describe '#raw_config_hash' do
    it 'has a legacy default URL' do
      expect(subject).to receive(:fetch_config) { false }

      expect(subject.send(:raw_config_hash)).to eq(url: 'redis://localhost:6382')
    end
  end

  describe '#store_name' do
    it 'returns the name of the SharedState store' do
      expect(described_class.store_name).to eq('SharedState')
    end
  end
end
