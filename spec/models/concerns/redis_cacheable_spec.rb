# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RedisCacheable do
  let(:model) do
    Struct.new(:id, :attributes) do
      def read_attribute(attribute)
        attributes[attribute]
      end

      def cast_value_from_cache(attribute, cached_value)
        cached_value
      end

      def has_attribute?(attribute)
        attributes.has_key?(attribute)
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
    subject { instance.cached_attribute(payload.each_key.first) }

    it 'gets the cache attribute' do
      Gitlab::Redis::Cache.with do |redis|
        expect(redis).to receive(:get).with(cache_key)
          .and_return(payload.to_json)
      end

      expect(subject).to eq(payload.each_value.first)
    end
  end

  describe '#cache_attributes' do
    subject { instance.cache_attributes(payload) }

    it 'sets the cache attributes' do
      Gitlab::Redis::Cache.with do |redis|
        expect(redis).to receive(:set).with(cache_key, payload.to_json, anything)
      end

      subject
    end

    context 'with existing cached attributes' do
      before do
        instance.cache_attributes({ existing_attr: 'value' })
      end

      it 'sets the cache attributes' do
        Gitlab::Redis::Cache.with do |redis|
          expect(redis).to receive(:set).with(cache_key, payload.to_json, anything).and_call_original
        end

        expect { subject }.to change { instance.cached_attribute(:existing_attr) }.from('value').to(nil)
      end
    end
  end

  describe '#merge_cache_attributes' do
    subject { instance.merge_cache_attributes(payload) }

    let(:existing_attributes) { { existing_attr: 'value', name: 'value' } }

    before do
      instance.cache_attributes(existing_attributes)
    end

    context 'with different attribute values' do
      let(:payload) { { name: 'new_value' } }

      it 'merges the cache attributes with existing values' do
        Gitlab::Redis::Cache.with do |redis|
          expect(redis).to receive(:set).with(cache_key, existing_attributes.merge(payload).to_json, anything)
            .and_call_original
        end

        subject

        expect(instance.cached_attribute(:existing_attr)).to eq 'value'
        expect(instance.cached_attribute(:name)).to eq 'new_value'
      end
    end

    context 'with no new or changed attribute values' do
      let(:payload) { { name: 'value' } }

      it 'does not try to set Redis key' do
        Gitlab::Redis::Cache.with do |redis|
          expect(redis).not_to receive(:set)
        end

        subject
      end
    end
  end

  describe '#cached_attr_reader', :clean_gitlab_redis_cache do
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

  describe '#cast_value_from_cache' do
    subject { instance.__send__(:cast_value_from_cache, attribute, value) }

    context 'with runner contacted_at' do
      let(:instance) { Ci::Runner.new }
      let(:attribute) { :contacted_at }
      let(:value) { '2018-05-07 13:53:08 UTC' }

      it 'converts cache string to appropriate type' do
        expect(subject).to be_an_instance_of(ActiveSupport::TimeWithZone)
      end
    end
  end
end
