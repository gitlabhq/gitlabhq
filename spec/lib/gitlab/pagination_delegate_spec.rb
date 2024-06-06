# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PaginationDelegate do
  context 'when there is no data' do
    let(:delegate) do
      described_class.new(page: 1,
        per_page: 10,
        count: 0)
    end

    it 'shows the correct total count' do
      expect(delegate.total_count).to eq(0)
    end

    it 'shows the correct total pages' do
      expect(delegate.total_pages).to eq(0)
    end

    it 'shows the correct next page' do
      expect(delegate.next_page).to be_nil
    end

    it 'shows the correct previous page' do
      expect(delegate.prev_page).to be_nil
    end

    it 'shows the correct current page' do
      expect(delegate.current_page).to eq(1)
    end

    it 'shows the correct limit value' do
      expect(delegate.limit_value).to eq(10)
    end

    it 'shows the correct first page' do
      expect(delegate.first_page?).to be true
    end

    it 'shows the correct last page' do
      expect(delegate.last_page?).to be true
    end

    it 'shows the correct offset' do
      expect(delegate.offset).to eq(0)
    end
  end

  context 'with data' do
    let(:delegate) do
      described_class.new(page: 5,
        per_page: 100,
        count: 1000)
    end

    it 'shows the correct total count' do
      expect(delegate.total_count).to eq(1000)
    end

    it 'shows the correct total pages' do
      expect(delegate.total_pages).to eq(10)
    end

    it 'shows the correct next page' do
      expect(delegate.next_page).to eq(6)
    end

    it 'shows the correct previous page' do
      expect(delegate.prev_page).to eq(4)
    end

    it 'shows the correct current page' do
      expect(delegate.current_page).to eq(5)
    end

    it 'shows the correct limit value' do
      expect(delegate.limit_value).to eq(100)
    end

    it 'shows the correct first page' do
      expect(delegate.first_page?).to be false
    end

    it 'shows the correct last page' do
      expect(delegate.last_page?).to be false
    end

    it 'shows the correct offset' do
      expect(delegate.offset).to eq(400)
    end
  end

  context 'for last page' do
    let(:delegate) do
      described_class.new(page: 10,
        per_page: 100,
        count: 1000)
    end

    it 'shows the correct total count' do
      expect(delegate.total_count).to eq(1000)
    end

    it 'shows the correct total pages' do
      expect(delegate.total_pages).to eq(10)
    end

    it 'shows the correct next page' do
      expect(delegate.next_page).to be_nil
    end

    it 'shows the correct previous page' do
      expect(delegate.prev_page).to eq(9)
    end

    it 'shows the correct current page' do
      expect(delegate.current_page).to eq(10)
    end

    it 'shows the correct limit value' do
      expect(delegate.limit_value).to eq(100)
    end

    it 'shows the correct first page' do
      expect(delegate.first_page?).to be false
    end

    it 'shows the correct last page' do
      expect(delegate.last_page?).to be true
    end

    it 'shows the correct offset' do
      expect(delegate.offset).to eq(900)
    end
  end

  context 'with limits and defaults' do
    it 'has a maximum limit per page' do
      expect(described_class.new(page: nil,
        per_page: 1000,
        count: 0).limit_value).to eq(described_class::MAX_PER_PAGE)
    end

    it 'has a default per page' do
      expect(described_class.new(page: nil,
        per_page: nil,
        count: 0).limit_value).to eq(described_class::DEFAULT_PER_PAGE)
    end

    it 'has a maximum page' do
      expect(described_class.new(page: 100,
        per_page: 10,
        count: 1).current_page).to eq(1)
    end
  end

  context 'with an invalid per_page value' do
    it 'has a default per page' do
      expect(described_class.new(page: nil,
        per_page: { wrong: :value },
        count: 0).limit_value).to eq(described_class::DEFAULT_PER_PAGE)
    end
  end
end
