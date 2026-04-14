# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::GitalyClient::RefCollectionWithNextCursor, feature_category: :source_code_management do
  let(:message) { Struct.new(:pagination_cursor, :references, keyword_init: true) }
  let(:pagination_cursor) { Struct.new(:next_cursor, keyword_init: true) }
  let(:ref_1) { Gitaly::ListRefsResponse::Reference.new(name: 'refs/heads/main', target: 'abc123') }
  let(:ref_2) { Gitaly::ListRefsResponse::Reference.new(name: 'refs/heads/feature', target: 'def456') }

  subject(:collection) { described_class.new(streamed_response) }

  describe '#next_cursor' do
    subject { collection.next_cursor }

    context 'when cursor is in the first response' do
      let(:next_cursor_value) { 'eyJyZWZfbmFtZSI6InJlZnMvaGVhZHMvbWFpbiJ9' }
      let(:streamed_response) do
        [
          message.new(pagination_cursor: pagination_cursor.new(next_cursor: next_cursor_value), references: [ref_1]),
          message.new(pagination_cursor: pagination_cursor.new(next_cursor: ''), references: [ref_2])
        ]
      end

      it { is_expected.to eq(next_cursor_value) }
    end

    context 'when cursor is in a later response' do
      let(:next_cursor_value) { 'eyJyZWZfbmFtZSI6InJlZnMvaGVhZHMvZmVhdHVyZSJ9' }
      let(:streamed_response) do
        [
          message.new(pagination_cursor: nil, references: [ref_1]),
          message.new(pagination_cursor: pagination_cursor.new(next_cursor: next_cursor_value), references: [ref_2])
        ]
      end

      it { is_expected.to eq(next_cursor_value) }
    end

    context 'when cursor is in a final response with no refs' do
      let(:next_cursor_value) { 'eyJyZWZfbmFtZSI6InJlZnMvaGVhZHMvbWFpbiJ9' }
      let(:streamed_response) do
        [
          message.new(pagination_cursor: nil, references: [ref_1]),
          message.new(pagination_cursor: pagination_cursor.new(next_cursor: next_cursor_value), references: [])
        ]
      end

      it { is_expected.to eq(next_cursor_value) }

      it 'collects all refs' do
        expect(collection.count).to eq 1
      end
    end

    context 'when no cursor is present' do
      let(:streamed_response) do
        [
          message.new(pagination_cursor: nil, references: [ref_1]),
          message.new(pagination_cursor: pagination_cursor.new(next_cursor: ''), references: [ref_2])
        ]
      end

      it { is_expected.to be_nil }
    end
  end

  describe 'delegated array behavior' do
    let(:streamed_response) do
      [
        message.new(pagination_cursor: nil, references: [ref_1]),
        message.new(pagination_cursor: nil, references: [ref_2])
      ]
    end

    it 'is an Enumerable' do
      expect(collection).to be_an(Enumerable)
    end

    it 'behaves like an array' do
      expect(collection.count).to eq(2)
      expect(collection.first).to eq(ref_1)
      expect(collection.map(&:name)).to eq(['refs/heads/main', 'refs/heads/feature'])
    end
  end
end
