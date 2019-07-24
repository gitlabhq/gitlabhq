# frozen_string_literal: true

require 'spec_helper'

describe 'search/_form' do
  context 'when the search page is opened' do
    it 'displays the correct elements' do
      render

      expect(rendered).to have_selector('.search-field-holder.form-group')
      expect(rendered).to have_selector('label[for="dashboard_search"]')
    end
  end
end
