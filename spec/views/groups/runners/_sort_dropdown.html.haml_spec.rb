# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/runners/sort_dropdown.html.haml' do
  describe 'render' do
    let_it_be(:sort_options_hash) { { by_title: 'Title' } }
    let_it_be(:sort_title_created_date) { 'Created date' }

    before do
      allow(view).to receive(:sort).and_return('by_title')
    end

    describe 'when a sort option is not selected' do
      it 'renders a default sort option' do
        render 'groups/runners/sort_dropdown', sort_options_hash: sort_options_hash, sort_title_created_date: sort_title_created_date

        expect(rendered).to have_content 'Created date'
      end
    end

    describe 'when a sort option is selected' do
      it 'renders the selected sort option' do
        @sort = :by_title
        render 'groups/runners/sort_dropdown', sort_options_hash: sort_options_hash, sort_title_created_date: sort_title_created_date

        expect(rendered).to have_content 'Title'
      end
    end
  end
end
