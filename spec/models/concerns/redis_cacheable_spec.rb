require 'spec_helper'

describe RedisCacheable do
  let(:model) { double }

  before do
    model.extend(described_class)
    allow(model).to receive(:cache_attribute_key).and_return('key')
  end

  describe '#cached_attribute' do
    let(:payload) { { attribute: 'value' } }

    subject { model.cached_attribute(payload.keys.first) }

    it 'gets the cache attribute' do
      Gitlab::Redis::SharedState.with do |redis|
        expect(redis).to receive(:get).with('key')
          .and_return(payload.to_json)
      end

      expect(subject).to eq(payload.values.first)
    end
  end

  describe '#cache_attributes' do
    let(:values) { { name: 'new_name' } }

    subject { model.cache_attributes(values) }

    it 'sets the cache attributes' do
      Gitlab::Redis::SharedState.with do |redis|
        expect(redis).to receive(:set).with('key', values.to_json, anything)
      end

      subject
    end
  end
end
