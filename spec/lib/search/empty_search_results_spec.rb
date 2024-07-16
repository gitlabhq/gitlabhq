# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::EmptySearchResults, feature_category: :global_search do
  subject(:results) { described_class.new }

  describe '#objects' do
    it 'returns an empty array' do
      expect(results.objects).to match_array([])
    end
  end

  describe '#formatted_count' do
    it 'returns a zero' do
      expect(results.formatted_count).to eq('0')
    end
  end

  describe '#highlight_map' do
    it 'returns an empty hash' do
      expect(results.highlight_map).to eq({})
    end
  end

  describe '#aggregations' do
    it 'returns an empty array' do
      expect(results.aggregations).to match_array([])
    end
  end

  describe '#failed?' do
    it 'returns false' do
      expect(results.failed?).to eq false
    end
  end
end
