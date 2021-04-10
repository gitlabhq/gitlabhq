# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiHelper do
  describe '#wiki_page_title' do
    let_it_be(:page) { create(:wiki_page) }

    it 'sets the title for the show action' do
      expect(helper).to receive(:breadcrumb_title).with(page.human_title)
      expect(helper).to receive(:wiki_breadcrumb_dropdown_links).with(page.slug)
      expect(helper).to receive(:page_title).with(page.human_title, 'Wiki')
      expect(helper).to receive(:add_to_breadcrumbs).with('Wiki', helper.wiki_path(page.wiki))

      helper.wiki_page_title(page)
    end

    it 'sets the title for a custom action' do
      expect(helper).to receive(:breadcrumb_title).with(page.human_title)
      expect(helper).to receive(:wiki_breadcrumb_dropdown_links).with(page.slug)
      expect(helper).to receive(:page_title).with('Edit', page.human_title, 'Wiki')
      expect(helper).to receive(:add_to_breadcrumbs).with('Wiki', helper.wiki_path(page.wiki))

      helper.wiki_page_title(page, 'Edit')
    end

    it 'sets the title for an unsaved page' do
      expect(page).to receive(:persisted?).and_return(false)
      expect(helper).not_to receive(:breadcrumb_title)
      expect(helper).not_to receive(:wiki_breadcrumb_dropdown_links)
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
    let(:wiki_link) { helper.wiki_sort_controls(wiki, sort, direction) }
    let(:classes) { "gl-button btn btn-default btn-icon has-tooltip reverse-sort-btn qa-reverse-sort rspec-reverse-sort" }

    def expected_link(sort, direction, icon_class)
      path = "/#{wiki.project.full_path}/-/wikis/pages?direction=#{direction}&sort=#{sort}"

      helper.link_to(path, type: 'button', class: classes, title: 'Sort direction') do
        helper.sprite_icon("sort-#{icon_class}")
      end
    end

    context 'initial call' do
      let(:sort) { nil }
      let(:direction) { nil }

      it 'renders with default values' do
        expect(wiki_link).to eq(expected_link('title', 'desc', 'lowest'))
      end
    end

    context 'sort by title' do
      let(:sort) { 'title' }
      let(:direction) { 'asc' }

      it 'renders a link with opposite direction' do
        expect(wiki_link).to eq(expected_link('title', 'desc', 'lowest'))
      end
    end

    context 'sort by created_at' do
      let(:sort) { 'created_at' }
      let(:direction) { 'desc' }

      it 'renders a link with opposite direction' do
        expect(wiki_link).to eq(expected_link('created_at', 'asc', 'highest'))
      end
    end
  end

  describe '#wiki_sort_title' do
    it 'returns a title corresponding to a key' do
      expect(helper.wiki_sort_title('created_at')).to eq('Created date')
      expect(helper.wiki_sort_title('title')).to eq('Title')
    end

    it 'defaults to Title if a key is unknown' do
      expect(helper.wiki_sort_title('unknown')).to eq('Title')
    end
  end

  describe '#wiki_page_tracking_context' do
    let_it_be(:page) { create(:wiki_page, title: 'path/to/page 💩', content: '💩', format: :markdown) }

    subject { helper.wiki_page_tracking_context(page) }

    it 'returns the tracking context' do
      expect(subject).to eq(
        'wiki-format'               => :markdown,
        'wiki-title-size'           => 9,
        'wiki-content-size'         => 4,
        'wiki-directory-nest-level' => 2,
        'wiki-container-type'       => 'Project'
      )
    end

    it 'returns a nest level of zero for toplevel files' do
      expect(page).to receive(:path).and_return('page')
      expect(subject).to include('wiki-directory-nest-level' => 0)
    end
  end
end
