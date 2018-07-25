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
    context 'when the feature is persisted' do
      it 'returns true when feature name is a string' do
        Feature::FlipperFeature.create!(key: 'foo')

        feature = double(:feature, name: 'foo')

        expect(described_class.persisted?(feature)).to eq(true)
      end

      it 'returns true when feature name is a symbol' do
        Feature::FlipperFeature.create!(key: 'foo')

        feature = double(:feature, name: :foo)

        expect(described_class.persisted?(feature)).to eq(true)
      end
    end

    context 'when the feature is not persisted' do
      it 'returns false when feature name is a string' do
        feature = double(:feature, name: 'foo')

        expect(described_class.persisted?(feature)).to eq(false)
      end

      it 'returns false when feature name is a symbol' do
        feature = double(:feature, name: :bar)

        expect(described_class.persisted?(feature)).to eq(false)
      end
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

  describe '.flipper' do
    shared_examples 'a memoized Flipper instance' do
      it 'memoizes the Flipper instance' do
        expect(Flipper).to receive(:new).once.and_call_original

        2.times do
          described_class.flipper
        end
      end
    end

    context 'when request store is inactive' do
      before do
        described_class.instance_variable_set(:@flipper, nil)
      end

      it_behaves_like 'a memoized Flipper instance'
    end

    context 'when request store is inactive', :request_store do
      it_behaves_like 'a memoized Flipper instance'
    end
  end
end
