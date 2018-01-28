require 'spec_helper'

describe Feature do
  describe '.get' do
    let(:feature) { double(:feature) }
    let(:key) { 'my_feature' }

    it 'returns the Flipper feature' do
      expect_any_instance_of(Flipper::DSL).to receive(:feature).with(key)
        .and_return(feature)

      expect(described_class.get(key)).to be(feature)
    end
  end

  describe '.persisted_names' do
    it 'returns the names of the persisted features' do
      Feature::FlipperFeature.create!(key: 'foo')

      expect(described_class.persisted_names).to eq(%w[foo])
    end

    it 'returns an empty Array when no features are presisted' do
      expect(described_class.persisted_names).to be_empty
    end

    it 'caches the feature names when request store is active', :request_store do
      Feature::FlipperFeature.create!(key: 'foo')

      expect(Feature::FlipperFeature)
        .to receive(:feature_names)
        .once
        .and_call_original

      2.times do
        expect(described_class.persisted_names).to eq(%w[foo])
      end
    end
  end

  describe '.persisted?' do
    it 'returns true for a persisted feature' do
      Feature::FlipperFeature.create!(key: 'foo')

      feature = double(:feature, name: 'foo')

      expect(described_class.persisted?(feature)).to eq(true)
    end

    it 'returns false for a feature that is not persisted' do
      feature = double(:feature, name: 'foo')

      expect(described_class.persisted?(feature)).to eq(false)
    end
  end

  describe '.all' do
    let(:features) { Set.new }

    it 'returns the Flipper features as an array' do
      expect_any_instance_of(Flipper::DSL).to receive(:features)
        .and_return(features)

      expect(described_class.all).to eq(features.to_a)
    end
  end
end
