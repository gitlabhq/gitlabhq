# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'shared/wikis/_sidebar.html.haml', feature_category: :wiki do
  let_it_be(:project) { create(:project) }
  let_it_be(:wiki) { Wiki.for_container(project, project.first_owner) }

  before do
    assign(:wiki, wiki)
    assign(:project, project)
  end

  context 'The sidebar comes from a custom page' do
    before do
      assign(:sidebar_page, double('WikiPage', path: 'sidebar.md', slug: 'sidebar', content: 'Some sidebar content', wiki: wiki))
    end

    it 'does not show an alert' do
      render

      expect(rendered).not_to include('The sidebar failed to load')
      expect(rendered).not_to have_css('.gl-alert.gl-alert-info')
    end

    it 'renders the wiki content' do
      render

      expect(rendered).to include('Some sidebar content')
    end

    it 'sets edit_sidebar_url with edit param' do
      render

      sidebar_element = Nokogiri::HTML.fragment(rendered).at_css('#js-wiki-sidebar')
      edit_url = sidebar_element['data-edit-sidebar-url']

      expect(edit_url).to include('edit=true')
      expect(edit_url).not_to include('action=edit')
    end
  end
end
