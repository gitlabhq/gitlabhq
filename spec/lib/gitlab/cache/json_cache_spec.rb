# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cache::JsonCache, feature_category: :shared do
  let_it_be(:broadcast_message) { create(:broadcast_message) }

  let(:backend) { instance_double(ActiveSupport::Cache::RedisCacheStore).as_null_object }
  let(:namespace) { 'geo' }
  let(:key) { 'foo' }
  let(:expanded_key) { "#{namespace}:#{key}:#{Gitlab.revision}" }

  subject(:cache) { described_class.new(namespace: namespace, backend: backend) }

  describe '#active?' do
    context 'when backend respond to active? method' do
      it 'delegates to the underlying cache implementation' do
        backend = instance_double(Gitlab::SafeRequestStore::NullStore, active?: false)

        cache = described_class.new(namespace: namespace, backend: backend)

        expect(cache.active?).to eq(false)
      end
    end

    context 'when backend does not respond to active? method' do
      it 'returns true' do
        backend = instance_double(ActiveSupport::Cache::RedisCacheStore)

        cache = described_class.new(namespace: namespace, backend: backend)

        expect(cache.active?).to eq(true)
      end
    end
  end

  describe '#expire' do
    it 'calls delete from the backend on the cache_key' do
      cache = Class.new(described_class) do
        def expanded_cache_key(_key)
          ['_expanded_cache_key_']
        end
      end.new(namespace: namespace, backend: backend)

      cache.expire(key)

      expect(backend).to have_received(:delete).with('_expanded_cache_key_')
    end

    it 'raises an error' do
      expect { cache.expire(key) }.to raise_error(NoMethodError)
    end
  end

  describe '#read' do
    it 'raises an error' do
      expect { cache.read(key) }.to raise_error(NoMethodError)
    end
  end

  describe '#write' do
    it 'raises an error' do
      expect { cache.write(key, true) }.to raise_error(NoMethodError)
    end
  end

  describe '#fetch' do
    it 'raises an error' do
      expect { cache.fetch(key) }.to raise_error(NoMethodError)
    end
  end
end
