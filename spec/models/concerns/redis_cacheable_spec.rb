require 'spec_helper'

describe RedisCacheable do
  let(:model) do
    Struct.new(:id, :attributes) do
      def read_attribute(attribute)
        attributes[attribute]
      end

      def cast_value_from_cache(attribute, cached_value)
        cached_value
      end

      def self.attribute_names
        %w[name time]
      end
    end
  end

  let(:payload) { { name: 'value', time: Time.zone.now } }
  let(:instance) { model.new(1, payload) }
  let(:cache_key) { instance.__send__(:cache_attribute_key) }

  before do
    model.include(described_class)
  end

  describe '#cached_attribute' do
    subject { instance.cached_attribute(payload.keys.first) }

    it 'gets the cache attribute' do
      Gitlab::Redis::SharedState.with do |redis|
        expect(redis).to receive(:get).with(cache_key)
          .and_return(payload.to_json)
      end

      expect(subject).to eq(payload.values.first)
    end
  end

  describe '#cache_attributes' do
    subject { instance.cache_attributes(payload) }

    it 'sets the cache attributes' do
      Gitlab::Redis::SharedState.with do |redis|
        expect(redis).to receive(:set).with(cache_key, payload.to_json, anything)
      end

      subject
    end
  end

  describe '#cached_attr_reader', :clean_gitlab_redis_shared_state do
    subject { instance.name }

    before do
      model.cached_attr_reader(:name)
    end

    context 'when there is no cached value' do
      it 'reads the attribute' do
        expect(instance).to receive(:read_attribute).and_call_original

        expect(subject).to eq(payload[:name])
      end
    end

    context 'when there is a cached value' do
      it 'reads the cached value' do
        expect(instance).not_to receive(:read_attribute)

        instance.cache_attributes(payload)

        expect(subject).to eq(payload[:name])
      end
    end

    it 'always returns the latest values' do
      expect(instance.name).to eq(payload[:name])

      instance.cache_attributes(name: 'new_value')

      expect(instance.name).to eq('new_value')
    end
  end
end
