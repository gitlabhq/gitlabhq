# frozen_string_literal: true

require 'spec_helper'

describe 'search/_results' do
  before do
    controller.params[:action] = 'show'

    3.times { create(:issue) }

    @search_objects = Issue.page(1).per(2)
    @scope = 'issues'
    @search_term = 'foo'
  end

  it 'displays the page size' do
    render

    expect(rendered).to have_content('Showing 1 - 2 of 3 issues for foo')
  end

  context 'when search results do not have a count' do
    before do
      @search_objects = @search_objects.without_count
    end

    it 'does not display the page size' do
      render

      expect(rendered).not_to have_content(/Showing .* of .*/)
    end
  end
end
