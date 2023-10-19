# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/groups/_dropdown.html.haml' do
  describe 'render' do
    describe 'when a sort option is not selected' do
      before do
        render 'shared/groups/dropdown'
      end

      it 'renders a default sort option' do
        expect(rendered).to have_content 'Last created'
      end

      it 'renders correct sort by options' do
        html_rendered = Nokogiri::HTML(rendered)
        sort_options = Gitlab::Json.parse(html_rendered.css('div.dropdown')[0]['data-items'])

        expect(sort_options.size).to eq(6)
        expect(sort_options[0]['value']).to eq('name_asc')
        expect(sort_options[0]['text']).to eq(s_('SortOptions|Name'))

        expect(sort_options[1]['value']).to eq('name_desc')
        expect(sort_options[1]['text']).to eq(s_('SortOptions|Name, descending'))

        expect(sort_options[2]['value']).to eq('created_desc')
        expect(sort_options[2]['text']).to eq(s_('SortOptions|Last created'))

        expect(sort_options[3]['value']).to eq('created_asc')
        expect(sort_options[3]['text']).to eq(s_('SortOptions|Oldest created'))

        expect(sort_options[4]['value']).to eq('latest_activity_desc')
        expect(sort_options[4]['text']).to eq(_('Updated date'))

        expect(sort_options[5]['value']).to eq('latest_activity_asc')
        expect(sort_options[5]['text']).to eq(s_('SortOptions|Oldest updated'))
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
