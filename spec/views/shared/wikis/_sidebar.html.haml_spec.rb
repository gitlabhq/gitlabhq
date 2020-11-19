# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'shared/wikis/_sidebar.html.haml' do
  let_it_be(:project) { create(:project) }
  let_it_be(:wiki) { Wiki.for_container(project, project.default_owner) }

  before do
    assign(:wiki, wiki)
    assign(:project, project)
  end

  it 'includes a link to clone the repository' do
    render

    expect(rendered).to have_link('Clone repository')
  end

  context 'the wiki is not a project wiki' do
    it 'does not include the clone repository link' do
      allow(wiki).to receive(:container).and_return(create(:group))

      render

      expect(rendered).not_to have_link('Clone repository')
    end
  end

  context 'the sidebar failed to load' do
    before do
      assign(:sidebar_error, Object.new)
    end

    it 'reports this to the user' do
      render

      expect(rendered).to include('The sidebar failed to load')
      expect(rendered).to have_css('.gl-alert.gl-alert-info')
    end
  end

  context 'The sidebar comes from a custom page' do
    before do
      assign(:sidebar_page, double('WikiPage', path: 'sidebar.md', slug: 'sidebar', content: 'Some sidebar content'))
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
  end

  context 'The sidebar comes a list of wiki pages' do
    before do
      assign(:sidebar_wiki_entries, create_list(:wiki_page, 3, wiki: wiki))
      assign(:sidebar_limited, true)
      stub_template "../shared/wikis/_wiki_pages.html.erb" => "Entries: <%= @sidebar_wiki_entries.size %>"
      stub_template "../shared/wikis/_wiki_page.html.erb" => 'A WIKI PAGE'
    end

    it 'does not show an alert' do
      render

      expect(rendered).not_to include('The sidebar failed to load')
      expect(rendered).not_to have_css('.gl-alert.gl-alert-info')
    end

    it 'renders the wiki content' do
      render

      expect(rendered).to include('A WIKI PAGE' * 3)
      expect(rendered).to have_link('View All Pages')
    end

    context 'there is no more to see' do
      it 'does not invite the user to view more' do
        assign(:sidebar_limited, false)

        render

        expect(rendered).not_to have_link('View All Pages')
      end
    end
  end
end
