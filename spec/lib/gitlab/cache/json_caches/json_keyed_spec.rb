# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cache::JsonCaches::JsonKeyed, feature_category: :shared do
  let_it_be(:broadcast_message) { create(:broadcast_message) }

  let(:backend) { instance_double(ActiveSupport::Cache::RedisCacheStore).as_null_object }
  let(:namespace) { 'geo' }
  let(:key) { 'foo' }
  let(:expanded_key) { "#{namespace}:#{key}" }
  let(:cache_key_strategy) { :revision }
  let(:nested_cache_result) { nest_value(broadcast_message) }

  subject(:cache) do
    described_class.new(namespace: namespace, backend: backend, cache_key_strategy: cache_key_strategy)
  end

  describe '#expire' do
    context 'with cache_key concerns' do
      subject(:expire) { cache.expire(key) }

      it 'uses the expanded_key' do
        expect(backend).to receive(:delete).with(expanded_key)

        expire
      end

      context 'when namespace is nil' do
        let(:namespace) { nil }

        it 'uses the expanded_key' do
          expect(backend).to receive(:delete).with(key)

          expire
        end
      end
    end
  end

  describe '#read' do
    context 'when the cached value is a hash' do
      it 'returns nil when the data is not in a nested structure' do
        allow(backend).to receive(:read).with(expanded_key).and_return(%w[a b].to_json)

        expect(cache.read(key)).to be_nil
      end

      context 'when there are other nested keys in the cache' do
        it 'only returns the value we are concerned with' do
          current_cache = { '_other_revision_' => '_other_value_' }.merge(nested_cache_result).to_json
          allow(backend).to receive(:read).with(expanded_key).and_return(current_cache)

          expect(cache.read(key, System::BroadcastMessage)).to eq(broadcast_message)
        end
      end
    end

    context 'when cache_key_strategy is unknown' do
      let(:cache_key_strategy) { 'unknown' }

      it 'raises KeyError' do
        allow(backend).to receive(:read).with(expanded_key).and_return(json_value(true))

        expect { cache.read(key) }.to raise_error(KeyError)
      end
    end
  end

  describe '#write' do
    context 'when there is an existing value in the cache' do
      it 'preserves the existing value when writing a different key' do
        current_cache = { '_other_revision_' => broadcast_message }
        allow(backend).to receive(:read).with(expanded_key).and_return(current_cache.to_json)

        cache.write(key, broadcast_message)

        write_cache = current_cache.merge(nested_cache_result)
        expect(backend).to have_received(:write).with(expanded_key, write_cache.to_json, nil)
      end

      it 'overwrites existing value when writing the same key' do
        current_cache = { Gitlab.revision => '_old_value_' }
        allow(backend).to receive(:read).with(expanded_key).and_return(current_cache.to_json)

        cache.write(key, broadcast_message)

        expect(backend).to have_received(:write).with(expanded_key, json_value(broadcast_message), nil)
      end
    end

    context 'when using the version strategy' do
      let(:cache_key_strategy) { :version }

      it 'writes value to the cache with the given key' do
        cache.write(key, true)

        write_cache = { "#{Gitlab::VERSION}:#{Rails.version}" => true }.to_json
        expect(backend).to have_received(:write).with(expanded_key, write_cache, nil)
      end
    end
  end

  it_behaves_like 'Json Cache class'

  def json_value(value)
    nest_value(value).to_json
  end

  def nest_value(value)
    { Gitlab.revision => value }
  end
end
