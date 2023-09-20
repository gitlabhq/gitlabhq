# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::QueuesMetadata, feature_category: :redis do
  include_examples "redis_new_instance_shared_examples", 'queues_metadata', Gitlab::Redis::Queues
  include_examples "redis_shared_examples"

  describe '#pool' do
    let(:config_new_format_host) { "spec/fixtures/config/redis_new_format_host.yml" }
    let(:config_new_format_socket) { "spec/fixtures/config/redis_new_format_socket.yml" }

    subject { described_class.pool }

    around do |example|
      clear_pool
      example.run
    ensure
      clear_pool
    end

    before do
      allow(described_class).to receive(:config_file_name).and_return(config_new_format_host)

      allow(described_class).to receive(:config_file_name).and_return(config_new_format_host)
      allow(Gitlab::Redis::Queues).to receive(:config_file_name).and_return(config_new_format_socket)
    end

    it 'instantiates an instance of MultiStore' do
      subject.with do |redis_instance|
        expect(redis_instance).to be_instance_of(::Gitlab::Redis::MultiStore)

        expect(redis_instance.primary_store.connection[:id]).to eq("redis://test-host:6379/99")
        expect(redis_instance.secondary_store.connection[:id]).to eq("unix:///path/to/redis.sock/0")

        expect(redis_instance.instance_name).to eq('QueuesMetadata')
      end
    end

    it_behaves_like 'multi store feature flags', :use_primary_and_secondary_stores_for_queues_metadata,
      :use_primary_store_as_default_for_queues_metadata
  end
end
