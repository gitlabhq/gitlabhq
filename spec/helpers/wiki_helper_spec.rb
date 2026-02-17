# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiHelper, feature_category: :wiki do
  describe '#wiki_page_title' do
    let_it_be(:page) { create(:wiki_page) }

    it 'sets the title for the show action' do
      expect(helper).to receive(:breadcrumb_title).with(page.human_title)
      expect(helper).to receive(:wiki_breadcrumb_collapsed_links).with(page.slug)
      expect(helper).to receive(:page_title).with(page.human_title, 'Wiki')
      expect(helper).to receive(:add_to_breadcrumbs).with('Wiki', helper.wiki_path(page.wiki))

      helper.wiki_page_title(page)
    end

    it 'sets the title for a custom action' do
      expect(helper).to receive(:breadcrumb_title).with(page.human_title)
      expect(helper).to receive(:wiki_breadcrumb_collapsed_links).with(page.slug)
      expect(helper).to receive(:page_title).with('Edit', page.human_title, 'Wiki')
      expect(helper).to receive(:add_to_breadcrumbs).with('Wiki', helper.wiki_path(page.wiki))

      helper.wiki_page_title(page, 'Edit')
    end

    it 'sets the title for an unsaved page' do
      expect(page).to receive(:persisted?).and_return(false)
      expect(helper).not_to receive(:breadcrumb_title)
      expect(helper).not_to receive(:wiki_breadcrumb_collapsed_links)
      expect(helper).to receive(:page_title).with('Wiki')
      expect(helper).to receive(:add_to_breadcrumbs).with('Wiki', helper.wiki_path(page.wiki))

      helper.wiki_page_title(page)
    end
  end

  describe '#breadcrumb' do
    context 'when the page is at the root level' do
      it 'returns the capitalized page name' do
        slug = 'page-name'

        expect(helper.breadcrumb(slug)).to eq('Page name')
      end
    end

    context 'when the page is inside a directory' do
      it 'returns the capitalized name of each directory and of the page itself' do
        slug = 'dir_1/page-name'

        expect(helper.breadcrumb(slug)).to eq('Dir_1 / Page name')
      end
    end
  end

  describe '#wiki_breadcrumb_items' do
    let(:wiki) { build_stubbed(:wiki) }

    before do
      helper.instance_variable_set(:@wiki, wiki)
    end

    it 'builds breadcrumb items for each parent page' do
      items = helper.wiki_breadcrumb_items('home/Core-DevOps/CI-CD')

      expect(items).to eq(
        [
          { text: 'Home', href: wiki_page_path(wiki, 'home') },
          { text: 'Core DevOps', href: wiki_page_path(wiki, 'home/Core-DevOps') }
        ]
      )
    end

    it 'returns an empty array when page_slug is empty' do
      items = helper.wiki_breadcrumb_items('')

      expect(items).to eq([])
    end

    it 'returns an empty array for malformed slugs' do
      items = helper.wiki_breadcrumb_items('///home///')

      expect(items).to eq([])
    end
  end

  describe '#wiki_attachment_upload_url' do
    let_it_be(:wiki) { build_stubbed(:project_wiki) }

    before do
      @wiki = wiki
    end

    it 'returns the upload endpoint for project wikis' do
      expect(helper.wiki_attachment_upload_url).to end_with("/api/v4/projects/#{@wiki.project.id}/wikis/attachments")
    end

    it 'raises an exception for unsupported wiki containers' do
      allow(wiki).to receive(:container).and_return(User.new)

      expect do
        helper.wiki_attachment_upload_url
      end.to raise_error(TypeError)
    end
  end

  describe '#wiki_sort_controls' do
    let(:wiki) { create(:project_wiki) }

    before do
      allow(Pajamas::ButtonComponent).to receive(:new).and_call_original
    end

    def expected_link_args(direction, icon_class)
      path = "/#{wiki.project.full_path}/-/wikis/pages?direction=#{direction}"
      title = direction == 'desc' ? _('Sort direction: Ascending') : _('Sort direction: Descending')
      {
        href: path,
        icon: "sort-#{icon_class}",
        button_options: hash_including(title: title)
      }
    end

    context 'when initially rendering' do
      it 'uses default values' do
        helper.wiki_sort_controls(wiki, nil)

        expect(Pajamas::ButtonComponent).to have_received(:new).with(expected_link_args('desc', 'lowest'))
      end
    end

    context 'when the current sort order is ascending' do
      it 'renders a link with opposite direction' do
        helper.wiki_sort_controls(wiki, 'asc')

        expect(Pajamas::ButtonComponent).to have_received(:new).with(expected_link_args('desc', 'lowest'))
      end
    end

    context 'when the current sort order is descending' do
      it 'renders a link with opposite direction' do
        helper.wiki_sort_controls(wiki, 'desc')

        expect(Pajamas::ButtonComponent).to have_received(:new).with(expected_link_args('asc', 'highest'))
      end
    end
  end

  describe '#wiki_page_tracking_context' do
    let_it_be(:page) { create(:wiki_page, title: 'path/to/page 💩', content: '💩', format: :markdown) }

    subject { helper.wiki_page_tracking_context(page) }

    it 'returns the tracking context' do
      expect(subject).to eq(
        'wiki-format' => :markdown,
        'wiki-title-size' => 9,
        'wiki-content-size' => 4,
        'wiki-directory-nest-level' => 2,
        'wiki-container-type' => 'Project'
      )
    end

    it 'returns a nest level of zero for toplevel files' do
      expect(page).to receive(:path).and_return('page')
      expect(subject).to include('wiki-directory-nest-level' => 0)
    end
  end

  it_behaves_like 'wiki endpoint helpers' do
    let_it_be(:page) { create(:wiki_page) }
  end

  context 'for wiki subpages' do
    it_behaves_like 'wiki endpoint helpers' do
      let_it_be(:page) { create(:wiki_page, title: 'foo/bar') }
    end
  end

  describe '#wiki_sidebar_toggle_button' do
    let_it_be(:wiki) { build(:project_wiki) }

    subject { helper.wiki_sidebar_toggle_button }

    before do
      @wiki = wiki
      allow(Pajamas::ButtonComponent).to receive(:new).and_call_original
    end

    describe 'when wiki_floating_sidebar_toggle is enabled' do
      before do
        stub_feature_flags({ wiki_floating_sidebar_toggle: true })
      end

      it 'shows the sidebar icon and is hidden on large screens' do
        subject

        expect(Pajamas::ButtonComponent).to have_received(:new) do |**kwargs|
          expect(kwargs[:icon]).to eq('sidebar')
          expect(kwargs[:button_options][:class]).to include('@lg/panel:gl-hidden')
        end
      end
    end

    describe 'when wiki_floating_sidebar_toggle is disabled' do
      before do
        stub_feature_flags({ wiki_floating_sidebar_toggle: false })
      end

      it 'shows the list_bulleted icon and is visible on large screens' do
        subject

        expect(Pajamas::ButtonComponent).to have_received(:new) do |**kwargs|
          expect(kwargs[:icon]).to eq('list-bulleted')
          expect(kwargs[:button_options][:class]).not_to include('@lg/panel:gl-hidden')
        end
      end
    end
  end
end
