# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::RedisStoreFactory, feature_category: :redis do
  describe '#create' do
    let(:params) { { host: 'localhost' } }

    subject(:factory_create) { ::Redis::Store::Factory.create(params) } # rubocop:disable Rails/SaveBang -- redis-store does not implement create!

    context 'when using standalone Redis' do
      it 'does not create ClusterStore' do
        expect(Gitlab::Redis::ClusterStore).not_to receive(:new)

        factory_create
      end
    end

    context 'when using a Redis Cluster' do
      let(:params) { { nodes: ["redis://localhost:6001", "redis://localhost:6002"] } }

      it 'creates a ClusterStore' do
        expect(Gitlab::Redis::ClusterStore).to receive(:new).with(params.merge({ raw: false }))

        factory_create
      end
    end
  end

  describe '#extract_host_options_from_uri' do
    using RSpec::Parameterized::TableSyntax

    # rubocop:disable Layout/LineLength -- Table is more readable as one line
    where(:url, :scheme, :username, :password, :port, :path, :db) do
      "redis://localhost" | 'redis' | nil | nil | 6379 | nil | nil
      "rediss://localhost" | 'rediss' | nil | nil | 6379 | nil | nil
      "rediss://:password@localhost" | 'rediss' | nil | 'password' | 6379 | nil | nil
      "rediss://redis-user:password@localhost:6380?db=5" | 'rediss' | 'redis-user' | 'password' | 6380 | nil | "5"
      "unix://test-user:secret@/var/run/redis.sock?db=6" | nil | 'test-user' | 'secret' | nil | '/var/run/redis.sock' | "6"
    end
    # rubocop:enable Layout/LineLength

    subject(:extracted) { ::Redis::Store::Factory.extract_host_options_from_uri(url) }

    with_them do
      it 'extracts the URL components', :aggregate_failures do
        expect(extracted[:scheme]).to eq(scheme)
        expect(extracted[:username]).to eq(username)
        expect(extracted[:password]).to eq(password)
        expect(extracted[:path]).to eq(path)
        expect(extracted[:port]).to eq(port)
        expect(extracted[:db]).to eq(db)
      end
    end
  end
end
