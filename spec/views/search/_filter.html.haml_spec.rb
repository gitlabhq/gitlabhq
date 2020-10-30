# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'search/_filter' do
  context 'when the search page is opened' do
    it 'displays the correct elements' do
      render

      expect(rendered).to have_selector('label[for="dashboard_search_group"]')
      expect(rendered).to have_selector('input#js-search-group-dropdown')

      expect(rendered).to have_selector('label[for="dashboard_search_project"]')
      expect(rendered).to have_selector('button#dashboard_search_project')
    end
  end
end
