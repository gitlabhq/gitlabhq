# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cache::Import::Caching, :clean_gitlab_redis_cache do
  describe '.read' do
    it 'reads a value from the cache' do
      described_class.write('foo', 'bar')

      expect(described_class.read('foo')).to eq('bar')
    end

    it 'returns nil if the cache key does not exist' do
      expect(described_class.read('foo')).to be_nil
    end

    it 'refreshes the cache key if a value is present' do
      described_class.write('foo', 'bar')

      redis = double(:redis)

      expect(redis).to receive(:get).with(/foo/).and_return('bar')
      expect(redis).to receive(:expire).with(/foo/, described_class::TIMEOUT)
      expect(Gitlab::Redis::Cache).to receive(:with).twice.and_yield(redis)

      described_class.read('foo')
    end

    it 'does not refresh the cache key if a value is empty' do
      described_class.write('foo', nil)

      redis = double(:redis)

      expect(redis).to receive(:get).with(/foo/).and_return('')
      expect(redis).not_to receive(:expire)
      expect(Gitlab::Redis::Cache).to receive(:with).and_yield(redis)

      described_class.read('foo')
    end
  end

  describe '.read_integer' do
    it 'returns an Integer' do
      described_class.write('foo', '10')

      expect(described_class.read_integer('foo')).to eq(10)
    end

    it 'returns nil if no value was found' do
      expect(described_class.read_integer('foo')).to be_nil
    end
  end

  describe '.write' do
    it 'writes a value to the cache and returns the written value' do
      expect(described_class.write('foo', 10)).to eq(10)
      expect(described_class.read('foo')).to eq('10')
    end
  end

  describe '.set_add' do
    it 'adds a value to a set' do
      described_class.set_add('foo', 10)
      described_class.set_add('foo', 10)

      key = described_class.cache_key_for('foo')
      values = Gitlab::Redis::Cache.with { |r| r.smembers(key) }

      expect(values).to eq(['10'])
    end
  end

  describe '.set_includes?' do
    it 'returns false when the key does not exist' do
      expect(described_class.set_includes?('foo', 10)).to eq(false)
    end

    it 'returns false when the value is not present in the set' do
      described_class.set_add('foo', 10)

      expect(described_class.set_includes?('foo', 20)).to eq(false)
    end

    it 'returns true when the set includes the given value' do
      described_class.set_add('foo', 10)

      expect(described_class.set_includes?('foo', 10)).to eq(true)
    end
  end

  describe '.values_from_set' do
    it 'returns empty list when the set is empty' do
      expect(described_class.values_from_set('foo')).to eq([])
    end

    it 'returns the set list of values' do
      described_class.set_add('foo', 10)

      expect(described_class.values_from_set('foo')).to eq(['10'])
    end
  end

  describe '.hash_add' do
    it 'adds a value to a hash' do
      described_class.hash_add('foo', 1, 1)
      described_class.hash_add('foo', 2, 2)

      key = described_class.cache_key_for('foo')
      values = Gitlab::Redis::Cache.with { |r| r.hgetall(key) }

      expect(values).to eq({ '1' => '1', '2' => '2' })
    end
  end

  describe '.values_from_hash' do
    it 'returns empty hash when the hash is empty' do
      expect(described_class.values_from_hash('foo')).to eq({})
    end

    it 'returns the set list of values' do
      described_class.hash_add('foo', 1, 1)

      expect(described_class.values_from_hash('foo')).to eq({ '1' => '1' })
    end
  end

  describe '.write_multiple' do
    it 'sets multiple keys when key_prefix not set' do
      mapping = { 'foo' => 10, 'bar' => 20 }

      described_class.write_multiple(mapping)

      mapping.each do |key, value|
        full_key = described_class.cache_key_for(key)
        found = Gitlab::Redis::Cache.with { |r| r.get(full_key) }

        expect(found).to eq(value.to_s)
      end
    end

    it 'sets multiple keys with correct prefix' do
      mapping = { 'foo' => 10, 'bar' => 20 }

      described_class.write_multiple(mapping, key_prefix: 'pref/')

      mapping.each do |key, value|
        full_key = described_class.cache_key_for("pref/#{key}")
        found = Gitlab::Redis::Cache.with { |r| r.get(full_key) }

        expect(found).to eq(value.to_s)
      end
    end
  end

  describe '.expire' do
    it 'sets the expiration time of a key' do
      timeout = 1.hour.to_i

      described_class.write('foo', 'bar', timeout: 2.hours.to_i)
      described_class.expire('foo', timeout)

      key = described_class.cache_key_for('foo')
      found_ttl = Gitlab::Redis::Cache.with { |r| r.ttl(key) }

      expect(found_ttl).to be <= timeout
    end
  end
end
