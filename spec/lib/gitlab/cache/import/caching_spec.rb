# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cache::Import::Caching, :clean_gitlab_redis_shared_state, feature_category: :importers do
  shared_examples 'validated redis value' do
    let(:value) { double('value', to_s: Object.new) }

    it 'raise error if value.to_s does not return a String' do
      value_as_string = value.to_s
      message = /Value '#{value_as_string}' of type '#{value_as_string.class}' for '#{value.inspect}' is not a String/

      expect { subject }.to raise_error(message)
    end
  end

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
      expect(Gitlab::Redis::SharedState).to receive(:with).twice.and_yield(redis)

      described_class.read('foo')
    end

    it 'does not refresh the cache key if a value is empty' do
      described_class.write('foo', nil)

      redis = double(:redis)

      expect(redis).to receive(:get).with(/foo/).and_return('')
      expect(redis).not_to receive(:expire)
      expect(Gitlab::Redis::SharedState).to receive(:with).once.and_yield(redis)

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

    it_behaves_like 'validated redis value' do
      subject { described_class.write('foo', value) }
    end
  end

  describe '.increment_by' do
    it_behaves_like 'validated redis value' do
      subject { described_class.increment_by('foo', value) }
    end
  end

  describe '.increment' do
    it 'increment a key and returns the current value' do
      expect(described_class.increment('foo')).to eq(1)

      value = Gitlab::Redis::SharedState.with { |r| r.get(described_class.cache_key_for('foo')) }

      expect(value.to_i).to eq(1)
    end
  end

  describe '.set_add' do
    it 'adds a value to a set' do
      described_class.set_add('foo', 10)
      described_class.set_add('foo', 10)

      key = described_class.cache_key_for('foo')
      values = Gitlab::Redis::SharedState.with { |r| r.smembers(key) }

      expect(values).to eq(['10'])
    end

    it_behaves_like 'validated redis value' do
      subject { described_class.set_add('foo', value) }
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

    it_behaves_like 'validated redis value' do
      subject { described_class.set_includes?('foo', value) }
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

  describe '.limited_values_from_set' do
    it 'returns empty array when the set does not exist' do
      expect(described_class.limited_values_from_set('foo')).to eq([])
    end

    it 'returns a single random member from the set' do
      described_class.set_add('foo', 10)
      described_class.set_add('foo', 20)

      result = described_class.limited_values_from_set('foo')

      expect(result.size).to eq(1)
      expect(result.first).to be_in(%w[10 20])
    end

    it 'returns multiple random members from the set with `limit:`' do
      described_class.set_add('foo', 10)
      described_class.set_add('foo', 20)
      described_class.set_add('foo', 30)

      result = described_class.limited_values_from_set('foo', limit: 2)

      expect(result.size).to eq(2)
      expect(result).to all(be_in(%w[10 20 30]))
    end
  end

  describe '.set_remove' do
    it 'returns 0 when the set does not exist' do
      expect(described_class.set_remove('foo', 1)).to eq(0)
    end

    it 'removes a single value from the set' do
      described_class.set_add('foo', 10)
      described_class.set_add('foo', 20)

      result = described_class.set_remove('foo', 20)

      expect(result).to eq(1)
      expect(described_class.values_from_set('foo')).to contain_exactly('10')
    end

    it 'removes a collection of values from the set' do
      described_class.set_add('foo', 10)
      described_class.set_add('foo', 20)
      described_class.set_add('foo', 30)

      result = described_class.set_remove('foo', [10, 30])

      expect(result).to eq(2)
      expect(described_class.values_from_set('foo')).to contain_exactly('20')
    end
  end

  describe '.set_count' do
    it 'returns 0 when the set does not exist' do
      expect(described_class.set_count('foo')).to eq(0)
    end

    it 'returns count of set' do
      described_class.set_add('foo', 10)
      described_class.set_add('foo', 20)

      expect(described_class.set_count('foo')).to eq(2)
    end
  end

  describe '.hash_add' do
    it 'adds a value to a hash' do
      described_class.hash_add('foo', 1, 1)
      described_class.hash_add('foo', 2, 2)

      key = described_class.cache_key_for('foo')
      values = Gitlab::Redis::SharedState.with { |r| r.hgetall(key) }

      expect(values).to eq({ '1' => '1', '2' => '2' })
    end

    it_behaves_like 'validated redis value' do
      subject { described_class.hash_add('foo', 1, value) }
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

  describe '.value_from_hash' do
    it 'returns nil when field was not set' do
      expect(described_class.value_from_hash('foo', 'bar')).to eq(nil)
    end

    it 'returns the value of the field' do
      described_class.hash_add('foo', 'bar', 1)

      expect(described_class.value_from_hash('foo', 'bar')).to eq('1')
    end

    it 'refreshes the cache key if a value is present' do
      described_class.hash_add('foo', 'bar', 1)

      redis = double(:redis)

      expect(redis).to receive(:hget).with(/foo/, 'bar').and_return('1')
      expect(redis).to receive(:expire).with(/foo/, described_class::TIMEOUT)
      expect(Gitlab::Redis::SharedState).to receive(:with).twice.and_yield(redis)

      described_class.value_from_hash('foo', 'bar')
    end
  end

  describe '.hash_increment' do
    it 'increments a value in a hash' do
      described_class.hash_increment('foo', 'field', 1)
      described_class.hash_increment('foo', 'field', 5)

      key = described_class.cache_key_for('foo')
      values = Gitlab::Redis::SharedState.with { |r| r.hgetall(key) }

      expect(values).to eq({ 'field' => '6' })
    end

    context 'when the value is not an integer' do
      it 'returns' do
        described_class.hash_increment('another-foo', 'another-field', 'not-an-integer')

        key = described_class.cache_key_for('foo')
        values = Gitlab::Redis::SharedState.with { |r| r.hgetall(key) }

        expect(values).to eq({})
      end
    end

    context 'when the value is less than 0' do
      it 'returns' do
        described_class.hash_increment('another-foo', 'another-field', -5)

        key = described_class.cache_key_for('foo')
        values = Gitlab::Redis::SharedState.with { |r| r.hgetall(key) }

        expect(values).to eq({})
      end
    end
  end

  describe '.write_multiple' do
    it 'sets multiple keys when key_prefix not set' do
      mapping = { 'foo' => 10, 'bar' => 20 }

      described_class.write_multiple(mapping)

      mapping.each do |key, value|
        full_key = described_class.cache_key_for(key)
        found = Gitlab::Redis::SharedState.with { |r| r.get(full_key) }

        expect(found).to eq(value.to_s)
      end
    end

    it 'sets multiple keys with correct prefix' do
      mapping = { 'foo' => 10, 'bar' => 20 }

      described_class.write_multiple(mapping, key_prefix: 'pref/')

      mapping.each do |key, value|
        full_key = described_class.cache_key_for("pref/#{key}")
        found = Gitlab::Redis::SharedState.with { |r| r.get(full_key) }

        expect(found).to eq(value.to_s)
      end
    end

    it_behaves_like 'validated redis value' do
      let(:mapping) { { 'foo' => value, 'bar' => value } }

      subject { described_class.write_multiple(mapping) }
    end
  end

  describe '.expire' do
    it 'sets the expiration time of a key' do
      timeout = 1.hour.to_i

      described_class.write('foo', 'bar', timeout: 2.hours.to_i)
      described_class.expire('foo', timeout)

      key = described_class.cache_key_for('foo')
      found_ttl = Gitlab::Redis::SharedState.with { |r| r.ttl(key) }

      expect(found_ttl).to be <= timeout
    end
  end

  describe '.write_if_greater' do
    it_behaves_like 'validated redis value' do
      subject { described_class.write_if_greater('foo', value) }
    end
  end

  describe '.list_add' do
    it 'adds a value to a list' do
      described_class.list_add('foo', 10)
      described_class.list_add('foo', 20)

      key = described_class.cache_key_for('foo')
      values = Gitlab::Redis::SharedState.with { |r| r.lrange(key, 0, -1) }

      expect(values).to eq(%w[10 20])
    end

    context 'when a limit is provided' do
      it 'limits the size of the list to the number of items defined by the limit' do
        described_class.list_add('foo', 10, limit: 3)
        described_class.list_add('foo', 20, limit: 3)
        described_class.list_add('foo', 30, limit: 3)
        described_class.list_add('foo', 40, limit: 3)

        key = described_class.cache_key_for('foo')
        values = Gitlab::Redis::SharedState.with { |r| r.lrange(key, 0, -1) }

        expect(values).to eq(%w[20 30 40])
      end
    end

    it_behaves_like 'validated redis value' do
      subject { described_class.list_add('foo', value) }
    end
  end

  describe '.values_from_list' do
    it 'returns empty array when the list is empty' do
      expect(described_class.values_from_list('foo')).to eq([])
    end

    it 'returns the items stored in the list in order' do
      described_class.list_add('foo', 10)
      described_class.list_add('foo', 20)
      described_class.list_add('foo', 10)

      expect(described_class.values_from_list('foo')).to eq(%w[10 20 10])
    end
  end

  describe '.del' do
    it 'deletes the key' do
      described_class.write('foo', 'value')

      expect { described_class.del('foo') }.to change { described_class.read('foo') }.from('value').to(nil)
    end
  end
end
