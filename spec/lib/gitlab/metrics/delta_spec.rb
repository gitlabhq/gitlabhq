# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Metrics::Delta do
  let(:delta) { described_class.new }

  describe '#compared_with' do
    it 'returns the delta as a Numeric' do
      expect(delta.compared_with(5)).to eq(5)
    end

    it 'bases the delta on a previously used value' do
      expect(delta.compared_with(5)).to eq(5)
      expect(delta.compared_with(15)).to eq(10)
    end
  end
end
