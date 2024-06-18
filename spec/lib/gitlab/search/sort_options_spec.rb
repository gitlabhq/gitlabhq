# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/search/sort_options'

RSpec.describe ::Gitlab::Search::SortOptions, feature_category: :global_search do
  describe '.sort_and_direction' do
    context 'using order_by and sort' do
      it 'returns matched options' do
        expect(described_class.sort_and_direction('created_at', 'asc')).to eq(:created_at_asc)
        expect(described_class.sort_and_direction('created_at', 'desc')).to eq(:created_at_desc)
      end
    end

    context 'using just sort' do
      it 'returns matched options' do
        expect(described_class.sort_and_direction(nil, 'created_asc')).to eq(:created_at_asc)
        expect(described_class.sort_and_direction(nil, 'created_desc')).to eq(:created_at_desc)
      end
    end

    context 'when unknown option' do
      it 'returns unknown' do
        expect(described_class.sort_and_direction(nil, 'foo_asc')).to eq(:unknown)
        expect(described_class.sort_and_direction(nil, 'bar_desc')).to eq(:unknown)
        expect(described_class.sort_and_direction(nil, 'created_bar')).to eq(:unknown)

        expect(described_class.sort_and_direction('created_at', 'foo')).to eq(:unknown)
        expect(described_class.sort_and_direction('foo', 'desc')).to eq(:unknown)
        expect(described_class.sort_and_direction('created_at', nil)).to eq(:unknown)
      end
    end
  end
end
