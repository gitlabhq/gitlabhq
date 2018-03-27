require 'spec_helper'

describe Gitlab::Sherlock::LineSample do
  let(:sample) { described_class.new(150.0, 4) }

  describe '#duration' do
    it 'returns the duration' do
      expect(sample.duration).to eq(150.0)
    end
  end

  describe '#events' do
    it 'returns the amount of events' do
      expect(sample.events).to eq(4)
    end
  end

  describe '#percentage_of' do
    it 'returns the percentage of 1500.0' do
      expect(sample.percentage_of(1500.0)).to be_within(0.1).of(10.0)
    end
  end

  describe '#majority_of' do
    it 'returns true if the sample takes up the majority of the given duration' do
      expect(sample.majority_of?(500.0)).to eq(true)
    end

    it "returns false if the sample doesn't take up the majority of the given duration" do
      expect(sample.majority_of?(1500.0)).to eq(false)
    end
  end
end
