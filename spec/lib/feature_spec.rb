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

  describe '.all' do
    let(:features) { Set.new }

    it 'returns the Flipper features as an array' do
      expect_any_instance_of(Flipper::DSL).to receive(:features)
        .and_return(features)

      expect(described_class.all).to eq(features.to_a)
    end
  end
end
