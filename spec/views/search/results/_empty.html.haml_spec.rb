# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'search/results/_empty', feature_category: :global_search do
  let(:search_term) { nil }
  let(:user) { build(:user) }
  let(:scope) { 'issues' }
  let(:search_service_presenter) do
    instance_double(SearchServicePresenter, without_count?: false, advanced_search_enabled?: false)
  end

  before do
    allow(view).to receive(:current_user) { user }

    assign(:search_service_presenter, search_service_presenter)
    assign(:search_term, search_term)
    assign(:search_results, search_results)
    assign(:scope, scope)
  end

  context 'when search has no results' do
    let(:search_term) { 'Search Foo' }
    let(:search_results) { [] }

    it 'renders the empty state' do
      render

      expect(rendered).to have_css('.gl-empty-state')
      expect(rendered).to have_content('No results found')
      expect(rendered).to have_content('We couldn\'t find any')
    end
  end
end
