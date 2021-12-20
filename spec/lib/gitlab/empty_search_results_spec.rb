# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EmptySearchResults do
  subject { described_class.new }

  describe '#objects' do
    it 'returns an empty array' do
      expect(subject.objects).to match_array([])
    end
  end

  describe '#formatted_count' do
    it 'returns a zero' do
      expect(subject.formatted_count).to eq('0')
    end
  end

  describe '#highlight_map' do
    it 'returns an empty hash' do
      expect(subject.highlight_map).to eq({})
    end
  end

  describe '#aggregations' do
    it 'returns an empty array' do
      expect(subject.objects).to match_array([])
    end
  end
end
