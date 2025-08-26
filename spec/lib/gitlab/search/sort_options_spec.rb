# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/search/sort_options'

RSpec.describe ::Gitlab::Search::SortOptions, feature_category: :global_search do
  describe '.sort_and_direction' do
    context 'using order_by and sort' do
      it 'returns matched options for created_at' do
        expect(described_class.sort_and_direction('created_at', 'asc')).to eq(:created_at_asc)
        expect(described_class.sort_and_direction('created_at', 'desc')).to eq(:created_at_desc)
      end

      it 'returns matched options for updated_at' do
        expect(described_class.sort_and_direction('updated_at', 'asc')).to eq(:updated_at_asc)
        expect(described_class.sort_and_direction('updated_at', 'desc')).to eq(:updated_at_desc)
      end

      it 'returns matched options for popularity' do
        expect(described_class.sort_and_direction('popularity', 'asc')).to eq(:popularity_asc)
        expect(described_class.sort_and_direction('popularity', 'desc')).to eq(:popularity_desc)
      end

      it 'returns matched options for milestone_due' do
        expect(described_class.sort_and_direction('milestone_due', 'asc')).to eq(:milestone_due_asc)
        expect(described_class.sort_and_direction('milestone_due', 'desc')).to eq(:milestone_due_desc)
      end

      it 'returns matched options for weight' do
        expect(described_class.sort_and_direction('weight', 'asc')).to eq(:weight_asc)
        expect(described_class.sort_and_direction('weight', 'desc')).to eq(:weight_desc)
      end

      it 'returns matched options for health_status' do
        expect(described_class.sort_and_direction('health_status', 'asc')).to eq(:health_status_asc)
        expect(described_class.sort_and_direction('health_status', 'desc')).to eq(:health_status_desc)
      end

      it 'returns matched options for closed_at' do
        expect(described_class.sort_and_direction('closed_at', 'asc')).to eq(:closed_at_asc)
        expect(described_class.sort_and_direction('closed_at', 'desc')).to eq(:closed_at_desc)
      end

      it 'returns matched options for due_date' do
        expect(described_class.sort_and_direction('due_date', 'asc')).to eq(:due_date_asc)
        expect(described_class.sort_and_direction('due_date', 'desc')).to eq(:due_date_desc)
      end
    end

    context 'using just sort' do
      it 'returns matched options for created' do
        expect(described_class.sort_and_direction(nil, 'created_asc')).to eq(:created_at_asc)
        expect(described_class.sort_and_direction(nil, 'created_desc')).to eq(:created_at_desc)
      end

      it 'returns matched options for updated' do
        expect(described_class.sort_and_direction(nil, 'updated_asc')).to eq(:updated_at_asc)
        expect(described_class.sort_and_direction(nil, 'updated_desc')).to eq(:updated_at_desc)
      end

      it 'returns matched options for popularity' do
        expect(described_class.sort_and_direction(nil, 'popularity_asc')).to eq(:popularity_asc)
        expect(described_class.sort_and_direction(nil, 'popularity_desc')).to eq(:popularity_desc)
      end

      it 'returns matched options for milestone_due' do
        expect(described_class.sort_and_direction(nil, 'milestone_due_asc')).to eq(:milestone_due_asc)
        expect(described_class.sort_and_direction(nil, 'milestone_due_desc')).to eq(:milestone_due_desc)
      end

      it 'returns matched options for weight' do
        expect(described_class.sort_and_direction(nil, 'weight_asc')).to eq(:weight_asc)
        expect(described_class.sort_and_direction(nil, 'weight_desc')).to eq(:weight_desc)
      end

      it 'returns matched options for health_status' do
        expect(described_class.sort_and_direction(nil, 'health_status_asc')).to eq(:health_status_asc)
        expect(described_class.sort_and_direction(nil, 'health_status_desc')).to eq(:health_status_desc)
      end

      it 'returns matched options for closed' do
        expect(described_class.sort_and_direction(nil, 'closed_at_asc')).to eq(:closed_at_asc)
        expect(described_class.sort_and_direction(nil, 'closed_at_desc')).to eq(:closed_at_desc)
      end

      it 'returns matched options for due' do
        expect(described_class.sort_and_direction(nil, 'due_date_asc')).to eq(:due_date_asc)
        expect(described_class.sort_and_direction(nil, 'due_date_desc')).to eq(:due_date_desc)
      end
    end

    context 'when unknown option' do
      it 'returns unknown for invalid sort-only parameters' do
        expect(described_class.sort_and_direction(nil, 'foo_asc')).to eq(:unknown)
        expect(described_class.sort_and_direction(nil, 'bar_desc')).to eq(:unknown)
        expect(described_class.sort_and_direction(nil, 'created_bar')).to eq(:unknown)
      end

      it 'returns unknown for invalid order_by and sort combinations' do
        expect(described_class.sort_and_direction('created_at', 'foo')).to eq(:unknown)
        expect(described_class.sort_and_direction('foo', 'desc')).to eq(:unknown)
        expect(described_class.sort_and_direction('created_at', nil)).to eq(:unknown)
      end
    end
  end
end
