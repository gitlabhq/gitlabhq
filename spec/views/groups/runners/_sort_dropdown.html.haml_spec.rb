# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/runners/sort_dropdown.html.haml' do
  describe 'render' do
    describe 'when a sort option is not selected' do
      it 'renders a default sort option' do
        render 'groups/runners/sort_dropdown'

        expect(rendered).to have_content _('Created date')
      end
    end

    describe 'when a sort option is selected' do
      before do
        assign(:sort, 'contacted_asc')
        render 'groups/runners/sort_dropdown'
      end

      it 'renders the selected sort option' do
        expect(rendered).to have_content _('Last Contact')
      end
    end
  end
end
