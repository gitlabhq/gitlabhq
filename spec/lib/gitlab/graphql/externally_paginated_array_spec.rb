# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Graphql::ExternallyPaginatedArray, feature_category: :api do
  it 'defaults total_count to nil and preserves cursors and elements', :aggregate_failures do
    array = described_class.new('prev', 'next', :a, :b, has_next_page: true)

    expect(array.to_a).to match_array([:a, :b])
    expect(array.start_cursor).to eq('prev')
    expect(array.end_cursor).to eq('next')
    expect(array.has_next_page).to be(true)
    expect(array.total_count).to be_nil
  end

  it 'stores a total_count value' do
    counter = -> { 42 }
    array = described_class.new('prev', 'next', :a, total_count: counter)

    expect(array.total_count).to eq(counter)
    expect(array.total_count.call).to eq(42)
  end

  describe '#precomputed_total_count' do
    it 'returns nil when no total_count was supplied' do
      array = described_class.new(nil, nil, :a)

      expect(array.precomputed_total_count).to be_nil
    end

    it 'returns total_count unchanged when it is not callable' do
      array = described_class.new(nil, nil, :a, total_count: 42)

      expect(array.precomputed_total_count).to eq(42)
    end

    it 'invokes total_count and returns its result when it is callable' do
      array = described_class.new(nil, nil, :a, total_count: -> { 7 })

      expect(array.precomputed_total_count).to eq(7)
    end
  end
end
