# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe BulkImports::Pipeline::ExtractedData do
  let(:data) { 'data' }
  let(:has_next_page) { true }
  let(:cursor) { 'cursor' }
  let(:page_info) do
    {
      'has_next_page' => has_next_page,
      'next_page' => cursor
    }
  end

  subject { described_class.new(data: data, page_info: page_info) }

  describe '#has_next_page?' do
    context 'when next page is present' do
      it 'returns true' do
        expect(subject.has_next_page?).to eq(true)
      end
    end

    context 'when next page is not present' do
      let(:has_next_page) { false }

      it 'returns false' do
        expect(subject.has_next_page?).to eq(false)
      end
    end
  end

  describe '#next_page' do
    it 'returns next page cursor information' do
      expect(subject.next_page).to eq(cursor)
    end
  end

  describe '#each' do
    context 'when block is present' do
      it 'yields each data item' do
        expect { |b| subject.each(&b) }.to yield_control
      end
    end

    context 'when block is not present' do
      it 'returns enumerator' do
        expect(subject.each).to be_instance_of(Enumerator)
      end
    end
  end

  describe '#each_with_index' do
    context 'when block is present' do
      it 'yields each data item with index' do
        expect { |b| subject.each_with_index(&b) }.to yield_control
      end
    end

    context 'when block is not present' do
      it 'returns enumerator' do
        expect(subject.each_with_index).to be_instance_of(Enumerator)
      end
    end
  end
end
