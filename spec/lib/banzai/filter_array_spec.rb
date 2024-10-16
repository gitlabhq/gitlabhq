# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Banzai::FilterArray, feature_category: :markdown do
  describe '#insert_after' do
    it 'inserts an element after a provided element' do
      filters = described_class.new(%w[a b c])

      filters.insert_after('b', '1')

      expect(filters).to eq %w[a b 1 c]
    end

    it 'inserts an element at the end when the provided element does not exist' do
      filters = described_class.new(%w[a b c])

      filters.insert_after('d', '1')

      expect(filters).to eq %w[a b c 1]
    end
  end

  describe '#insert_before' do
    it 'inserts an element before a provided element' do
      filters = described_class.new(%w[a b c])

      filters.insert_before('b', '1')

      expect(filters).to eq %w[a 1 b c]
    end

    it 'inserts an element at the beginning when the provided element does not exist' do
      filters = described_class.new(%w[a b c])

      filters.insert_before('d', '1')

      expect(filters).to eq %w[1 a b c]
    end
  end
end
