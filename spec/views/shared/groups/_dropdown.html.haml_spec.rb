# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/groups/_dropdown.html.haml' do
  describe 'render' do
    describe 'when a sort option is not selected' do
      it 'renders a default sort option' do
        render 'shared/groups/dropdown'

        expect(rendered).to have_content 'Last created'
      end
    end

    describe 'when a sort option is selected' do
      before do
        assign(:sort, 'name_desc')

        render 'shared/groups/dropdown'
      end

      it 'renders the selected sort option' do
        expect(rendered).to have_content 'Name, descending'
      end
    end
  end
end
