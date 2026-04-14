# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkItems::SortingKeys, feature_category: :team_planning do
  describe '.order_by_values' do
    it 'returns unique column names without direction suffixes' do
      expect(described_class.order_by_values).to all(satisfy { |v| !v.end_with?('_asc', '_desc') })
      expect(described_class.order_by_values).to eq(described_class.order_by_values.uniq)
    end

    it 'expands short created/updated forms to their _at equivalents' do
      expect(described_class.order_by_values).to include('created_at', 'updated_at')
      expect(described_class.order_by_values).not_to include('created', 'updated')
    end

    it 'covers all default sorting keys' do
      default_columns = WorkItems::SortingKeys::DEFAULT_SORTING_KEYS.keys.map do |key|
        col = key.to_s.sub(/_(?:asc|desc)\z/, '')
        col.in?(%w[created updated]) ? "#{col}_at" : col
      end.uniq

      expect(described_class.order_by_values).to include(*default_columns)
    end
  end

  describe '#available?' do
    context 'when no widget list is given' do
      it 'returns true when passing a default sorting key' do
        expect(described_class.available?('title_desc')).to be(true)
      end

      it 'returns false when passing a default sorting key' do
        expect(described_class.available?('unknown')).to be(false)
      end
    end

    context 'when widget list is given' do
      let_it_be(:widget_list) { [WorkItems::Widgets::Milestone] }

      it 'returns true when passing a default sorting key' do
        sorting_key = widget_list.sample.sorting_keys.keys.sample
        expect(described_class.available?(sorting_key, widget_list: widget_list)).to be(true)
      end

      it 'returns false when passing an unknown sorting key' do
        expect(described_class.available?('unknown', widget_list: widget_list)).to be(false)
      end
    end
  end

  context 'when widget list is given' do
    let_it_be(:widget_list) { [WorkItems::Widgets::Milestone] }

    it 'returns true when passing a default sorting key' do
      sorting_key = widget_list.sample.sorting_keys.keys.sample
      expect(described_class.available?(sorting_key, widget_list: widget_list)).to be(true)
    end

    it 'returns false when passing an unknown sorting key' do
      expect(described_class.available?('unknown', widget_list: widget_list)).to be(false)
    end
  end
end
