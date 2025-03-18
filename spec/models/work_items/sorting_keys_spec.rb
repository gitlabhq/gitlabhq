# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkItems::SortingKeys, feature_category: :team_planning do
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
end
