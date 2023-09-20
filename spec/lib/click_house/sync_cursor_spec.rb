# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::SyncCursor, feature_category: :value_stream_management, click_house: {} do
  def value
    ClickHouse::SyncCursor.cursor_for(:my_table)
  end

  context 'when cursor is empty' do
    it 'returns the default value: 0' do
      expect(value).to eq(0)
    end
  end

  context 'when cursor is present' do
    it 'updates and returns the current cursor value' do
      described_class.update_cursor_for(:my_table, 1111)

      expect(value).to eq(1111)

      described_class.update_cursor_for(:my_table, 2222)

      expect(value).to eq(2222)
    end
  end

  context 'when updating a different cursor' do
    it 'does not affect the other cursors' do
      described_class.update_cursor_for(:other_table, 1111)

      expect(value).to eq(0)
    end
  end
end
