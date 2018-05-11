require 'spec_helper'

describe RedisCacheable do
  let(:model) do
    Struct.new(:id, :attributes) do
      def read_attribute(attribute)
        attributes[attribute]
      end
    end
  end

  let(:payload) { { name: 'value' } }
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

  describe '#cached_attr_reader' do
    subject { instance.name }

    before do
      model.cached_attr_reader(:name)
    end

    context 'when there is no cached value' do
      it 'checks the cached value first then reads the attribute' do
        expect(instance).to receive(:cached_attribute).and_return(nil)
        expect(instance).to receive(:read_attribute).and_return(payload[:name])

        expect(subject).to eq(payload[:name])
      end
    end

    context 'when there is a cached value' do
      it 'reads the cached value' do
        expect(instance).to receive(:cached_attribute).and_return(payload[:name])
        expect(instance).not_to receive(:read_attribute)

        expect(subject).to eq(payload[:name])
      end
    end
  end

  describe '#cached_attr_time_reader' do
    subject { instance.time }

    before do
      model.cached_attr_time_reader(:time)
    end

    context 'when there is no cached value' do
      it 'checks the cached value first then reads the attribute' do
        expect(instance).to receive(:cached_attribute).and_return(nil)
        expect(instance).to receive(:read_attribute).and_return(Time.zone.now)

        expect(subject).to be_instance_of(ActiveSupport::TimeWithZone)
        expect(subject).to be_within(1.minute).of(Time.zone.now)
      end
    end

    context 'when there is a cached value' do
      it 'reads the cached value' do
        expect(instance).to receive(:cached_attribute).and_return(Time.zone.now.to_s)
        expect(instance).not_to receive(:read_attribute)

        expect(subject).to be_instance_of(ActiveSupport::TimeWithZone)
        expect(subject).to be_within(1.minute).of(Time.zone.now)
      end
    end
  end
end
