# frozen_string_literal: true

require 'fast_spec_helper'

# Emulates paginator. It returns 2 pages with results
class TestPaginator
  def initialize
    @current_page = 0
  end

  def items
    @current_page += 1

    raise StopIteration if @current_page > 2

    ["result_1_page_#{@current_page}", "result_2_page_#{@current_page}"]
  end

  def page_info
    {
      has_next_page: @current_page < 2,
      has_previous_page: @current_page > 1,
      start_cursor: 'start',
      end_cursor: 'end'
    }
  end
end

RSpec.describe Bitbucket::Collection, feature_category: :importers do
  it "iterates paginator" do
    collection = described_class.new(TestPaginator.new)

    expect(collection.to_a).to match(%w[result_1_page_1 result_2_page_1 result_1_page_2 result_2_page_2])
  end

  describe '#page_info' do
    it 'delegates to paginator' do
      paginator = TestPaginator.new
      collection = described_class.new(paginator)

      expect(collection.page_info).to eq(paginator.page_info)
    end

    it 'returns page info from paginator' do
      paginator = TestPaginator.new
      collection = described_class.new(paginator)

      page_info = collection.page_info

      expect(page_info).to be_a(Hash)
      expect(page_info).to have_key(:has_next_page)
      expect(page_info).to have_key(:has_previous_page)
      expect(page_info).to have_key(:start_cursor)
      expect(page_info).to have_key(:end_cursor)
    end
  end
end
