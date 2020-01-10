# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Pagination::Keyset::Page do
  describe '#per_page' do
    it 'limits to a maximum of 100 records per page' do
      per_page = described_class.new(per_page: 101).per_page

      expect(per_page).to eq(described_class::MAXIMUM_PAGE_SIZE)
    end

    it 'uses default value when given 0' do
      per_page = described_class.new(per_page: 0).per_page

      expect(per_page).to eq(described_class::DEFAULT_PAGE_SIZE)
    end

    it 'uses default value when given negative values' do
      per_page = described_class.new(per_page: -1).per_page

      expect(per_page).to eq(described_class::DEFAULT_PAGE_SIZE)
    end

    it 'uses the given value if it is within range' do
      per_page = described_class.new(per_page: 10).per_page

      expect(per_page).to eq(10)
    end
  end

  describe '#next' do
    let(:page) { described_class.new(order_by: order_by, lower_bounds: lower_bounds, per_page: per_page) }
    subject { page.next(new_lower_bounds) }

    let(:order_by) { { id: :desc } }
    let(:lower_bounds) { { id: 42 } }
    let(:per_page) { 10 }

    let(:new_lower_bounds) { { id: 21 } }

    it 'copies over order_by' do
      expect(subject.order_by).to eq(page.order_by)
    end

    it 'copies over per_page' do
      expect(subject.per_page).to eq(page.per_page)
    end

    it 'dups the instance' do
      expect(subject).not_to eq(page)
    end

    it 'sets lower_bounds only on new instance' do
      expect(subject.lower_bounds).to eq(new_lower_bounds)
      expect(page.lower_bounds).to eq(lower_bounds)
    end
  end
end
