# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::EmptySearchResults, feature_category: :global_search do
  subject(:results) { described_class.new }

  describe '#objects' do
    it 'returns an empty array' do
      expect(results.objects).to be_empty
    end
  end

  describe '#formatted_count' do
    it 'returns a zero' do
      expect(results.formatted_count).to eq('0')
    end
  end

  describe '#blobs_count' do
    it 'returns a zero' do
      expect(results.blobs_count).to eq(0)
    end
  end

  describe '#file_count' do
    it 'returns a zero' do
      expect(results.file_count).to eq(0)
    end
  end

  describe '#highlight_map' do
    it 'returns an empty hash' do
      expect(results.highlight_map).to eq({})
    end
  end

  describe '#aggregations' do
    it 'returns an empty array' do
      expect(results.aggregations).to be_empty
    end
  end

  describe '#failed?' do
    [true, false].each do |failure|
      it "returns #{failure} when passed an error option" do
        error_message = failure ? 'error message' : nil
        results = described_class.new(error: error_message)
        expect(results.failed?).to eq failure
        expect(results.error).to eq error_message
      end
    end
  end
end
