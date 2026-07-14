# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RequestCost, feature_category: :rate_limiting do
  describe '.current' do
    context 'when SafeRequestStore is active', :request_store do
      it 'returns a per-request RequestCost instance' do
        first  = described_class.current
        second = described_class.current

        expect(first).to be_a(described_class)
        expect(first).to equal(second)
      end

      it 'isolates state per request' do
        described_class.current.add(3, resource: :gitaly)

        expect(described_class.current.get(:gitaly)).to eq(3)
      end
    end

    context 'when SafeRequestStore is not active' do
      before do
        allow(Gitlab::SafeRequestStore).to receive(:active?).and_return(false)
      end

      it 'returns a NullCost' do
        expect(described_class.current).to be_a(described_class::NullCost)
      end

      it 'silently absorbs writes and returns zero on reads' do
        expect { described_class.current.add(5, resource: :gitaly) }.not_to raise_error
        expect(described_class.current.get(:gitaly)).to eq(0)
      end
    end
  end

  describe '#add and #get', :request_store do
    subject(:cost) { described_class.new }

    it 'starts at zero for any unknown resource' do
      expect(cost.get(:gitaly)).to eq(0)
      expect(cost.get(:database)).to eq(0)
    end

    it 'accumulates per resource' do
      cost.add(2, resource: :gitaly)
      cost.add(3, resource: :gitaly)

      expect(cost.get(:gitaly)).to eq(5)
    end

    it 'tracks resources independently' do
      cost.add(2, resource: :gitaly)
      cost.add(7, resource: :database)

      expect(cost.get(:gitaly)).to eq(2)
      expect(cost.get(:database)).to eq(7)
    end
  end
end
