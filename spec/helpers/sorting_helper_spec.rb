# frozen_string_literal: true
require 'spec_helper'

describe SortingHelper do
  include ApplicationHelper
  include IconsHelper

  describe '#issuable_sort_option_title' do
    it 'returns correct title for issuable_sort_option_overrides key' do
      expect(issuable_sort_option_title('created_asc')).to eq('Created date')
    end

    it 'returns correct title for a valid sort value' do
      expect(issuable_sort_option_title('priority')).to eq('Priority')
    end

    it 'returns nil for invalid sort value' do
      expect(issuable_sort_option_title('invalid_key')).to eq(nil)
    end
  end

  describe '#issuable_sort_direction_button' do
    before do
      allow(self).to receive(:request).and_return(double(path: 'http://test.com', query_parameters: { label_name: 'test_label' }))
    end

    it 'keeps label filter param' do
      expect(issuable_sort_direction_button('created_date')).to include('label_name=test_label')
    end

    it 'returns icon with sort-highest when sort is created_date' do
      expect(issuable_sort_direction_button('created_date')).to include('sort-highest')
    end

    it 'returns icon with sort-lowest when sort is asc' do
      expect(issuable_sort_direction_button('created_asc')).to include('sort-lowest')
    end

    it 'returns icon with sort-lowest when sorting by milestone' do
      expect(issuable_sort_direction_button('milestone')).to include('sort-lowest')
    end

    it 'returns icon with sort-lowest when sorting by due_date' do
      expect(issuable_sort_direction_button('due_date')).to include('sort-lowest')
    end
  end
end
