# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/_milestones_sort_dropdown.html.haml' do
  describe 'render' do
    describe 'when a sort option is not selected' do
      it 'renders a default sort option' do
        render 'shared/milestones_sort_dropdown'

        expect(rendered).to have_content 'Due soon'
      end
    end

    describe 'when a sort option is selected' do
      before do
        assign(:sort, 'due_date_desc')

        render 'shared/milestones_sort_dropdown'
      end

      it 'renders the selected sort option' do
        expect(rendered).to have_content 'Due later'
      end
    end
  end
end
