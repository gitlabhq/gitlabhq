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
end

RSpec.describe Bitbucket::Collection do
  it "iterates paginator" do
    collection = described_class.new(TestPaginator.new)

    expect(collection.to_a).to match(%w[result_1_page_1 result_2_page_1 result_1_page_2 result_2_page_2])
  end
end
