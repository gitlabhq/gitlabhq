# frozen_string_literal: true

require 'spec_helper'

# This spec only runs if a Redis Cluster is configured for Gitlab::Redis::Cache.
# ::Redis::Cluster fetches the cluster details from the server on `initialize` and will raise
# an error if the cluster is not found.
#
# An example would be the following in config/redis.yml assuming gdk is set up with redis-cluster.
# test:
#   cache
#     cluster:
#       - "redis://127.0.0.1:6003"
#       - "redis://127.0.0.1:6004"
#       - "redis://127.0.0.1:6005"
RSpec.describe Gitlab::Redis::ClusterStore, :clean_gitlab_redis_cache,
  feature_category: :redis, if: ::Gitlab::Redis::Cache.params[:nodes] do
  let(:params) { ::Gitlab::Redis::Cache.params }

  subject(:store) { ::Redis::Store::Factory.create(params) } # rubocop:disable Rails/SaveBang -- not a rails method

  describe '.new' do
    it 'initialises a cluster store' do
      expect(store).to be_instance_of(::Gitlab::Redis::ClusterStore)
    end

    it 'extends Serialization by default' do
      expect(store.is_a?(::Redis::Store::Serialization)).to eq(true)
    end

    it 'sets a default serializer when left empty' do
      expect(store.instance_variable_get(:@serializer)).to eq(Marshal)
    end

    context 'when serializer field is defined' do
      let(:params) { ::Gitlab::Redis::Cache.params.merge(serializer: Class) }

      it 'sets serializer according to the options' do
        expect(store.instance_variable_get(:@serializer)).to eq(Class)
      end
    end

    context 'when marshalling field is defined' do
      let(:params) { ::Gitlab::Redis::Cache.params.merge(marshalling: true, serializer: Class) }

      it 'overrides serializer with Marshal' do
        expect(store.instance_variable_get(:@serializer)).to eq(Marshal)
      end
    end

    context 'when marshalling field is false' do
      let(:params) { ::Gitlab::Redis::Cache.params.merge(marshalling: false, serializer: Class) }

      it 'overrides serializer with Marshal' do
        expect(store.instance_variable_get(:@serializer)).to eq(nil)
      end
    end

    context 'when namespace is defined' do
      let(:params) { ::Gitlab::Redis::Cache.params.merge(namespace: 'testing') }

      it 'extends namespace' do
        expect(store.is_a?(::Redis::Store::Namespace)).to eq(true)
      end

      it 'write keys with namespace' do
        store.set('testkey', 1)

        ::Gitlab::Redis::Cache.with do |conn|
          expect(conn.exists('testing:testkey')).to eq(1)
        end
      end
    end
  end

  describe '#set' do
    context 'when ttl is added' do
      it 'writes the key and sets a ttl' do
        expect(store.set('test', 1, expire_after: 100)).to eq('OK')

        expect(store.ttl('test')).to be > 95
        expect(store.get('test')).to eq(1)
      end
    end

    context 'when there is no ttl' do
      it 'sets the key' do
        expect(store.set('test', 1)).to eq('OK')

        expect(store.get('test')).to eq(1)
        expect(store.ttl('test')).to eq(-1)
      end
    end
  end

  describe '#setnx' do
    context 'when ttl is added' do
      it 'writes the key if not exists and sets a ttl' do
        expect(store.setnx('test', 1, expire_after: 100)).to eq([true, true])
        expect(store.ttl('test')).to be > 95
        expect(store.get('test')).to eq(1)
        expect(store.setnx('test', 1, expire_after: 100)).to eq([false, true])
      end
    end

    context 'when there is no ttl' do
      it 'writes the key if not exists' do
        expect(store.setnx('test', 1)).to eq(true)
        expect(store.setnx('test', 1)).to eq(false)

        expect(store.get('test')).to eq(1)
        expect(store.ttl('test')).to eq(-1)
      end
    end
  end
end
