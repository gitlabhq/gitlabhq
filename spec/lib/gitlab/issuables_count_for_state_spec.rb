require 'spec_helper'

describe Gitlab::IssuablesCountForState do
  let(:finder) do
    double(:finder, count_by_state: { opened: 2, closed: 1 })
  end

  let(:counter) { described_class.new(finder) }

  describe '#for_state_or_opened' do
    it 'returns the number of issuables for the given state' do
      expect(counter.for_state_or_opened(:closed)).to eq(1)
    end

    it 'returns the number of open issuables when no state is given' do
      expect(counter.for_state_or_opened).to eq(2)
    end

    it 'returns the number of open issuables when a nil value is given' do
      expect(counter.for_state_or_opened(nil)).to eq(2)
    end
  end

  describe '#[]' do
    it 'returns the number of issuables for the given state' do
      expect(counter[:closed]).to eq(1)
    end

    it 'casts valid states from Strings to Symbols' do
      expect(counter['closed']).to eq(1)
    end

    it 'returns 0 when using an invalid state name as a String' do
      expect(counter['kittens']).to be_zero
    end
  end
end
