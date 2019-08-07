# frozen_string_literal: true

require 'spec_helper'

describe 'search/show' do
  let(:search_term) { nil }

  before do
    stub_template "search/_category.html.haml" => 'Category Partial'
    stub_template "search/_results.html.haml" => 'Results Partial'

    @search_term = search_term

    render
  end

  context 'when the search page is opened' do
    it 'displays the title' do
      expect(rendered).to have_selector('h1.page-title', text: 'Search')
      expect(rendered).not_to have_selector('h1.page-title code')
    end

    it 'does not render partials' do
      expect(rendered).not_to render_template('search/_category')
      expect(rendered).not_to render_template('search/_results')
    end
  end

  context 'when search term is supplied' do
    let(:search_term) { 'Search Foo' }

    it 'renders partials' do
      expect(rendered).to render_template('search/_category')
      expect(rendered).to render_template('search/_results')
    end
  end
end
