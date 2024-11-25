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
  end

  describe 'link to edit the sidebar' do
    context 'when the user has edit permission and there are wiki pages' do
      before do
        create(:wiki_page, wiki: wiki, title: 'home', content: 'Home page')
        assign(:wiki_pages_count, 3)
        allow(view).to receive(:can?).with(anything, :create_wiki, anything).and_return(can_edit)

        render
      end

      let(:can_edit) { true }

      it 'renders the link' do
        expect(rendered).to have_link('Add custom sidebar', href: wiki_page_path(wiki, Wiki::SIDEBAR, action: :edit))
      end
    end

    context 'when the user does not have edit permission and there are no wiki pages' do
      before do
        allow(view).to receive(:can?).with(anything, :create_wiki, anything).and_return(can_edit)

        render
      end

      let(:can_edit) { false }

      it 'does not render the link' do
        expect(rendered).not_to have_link('Add custom sidebar')
      end
    end
  end
end
