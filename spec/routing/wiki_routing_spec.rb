# frozen_string_literal: true

require 'spec_helper'

# We build URIs to wiki pages manually in various places (most notably
# in markdown generation). To ensure these do not get out of sync, these
# tests verify that our path generation assumptions are sound.
describe 'Wiki path generation assumptions' do
  set(:project) { create(:project, :public, :repository) }

  let(:project_wiki) { ProjectWiki.new(project, project.owner) }
  let(:some_page_name) { 'some-wiki-page' }
  let(:wiki_page) do
    create(:wiki_page, wiki: project_wiki, attrs: { title: some_page_name })
  end

  describe 'WikiProject#wiki_page_path', 'routing' do
    it 'is consistent with routing to wiki#show' do
      uri = URI.parse(project_wiki.wiki_page_path)
      path = ::File.join(uri.path, some_page_name)

      expect(get('/' + path)).to route_to('projects/wiki_pages#show',
                                          id: some_page_name,
                                          namespace_id: project.namespace.to_param,
                                          project_id: project.to_param)
    end
  end

  describe 'project_wiki_path', 'routing' do
    describe 'GET' do
      it 'routes to the :show action' do
        path = project_wiki_path(project, wiki_page)

        expect(get('/' + path)).to route_to('projects/wiki_pages#show',
                                            id: wiki_page.slug,
                                            namespace_id: project.namespace.to_param,
                                            project_id: project.to_param)
      end
    end
  end

  describe 'project_wiki_pages_new_path', 'routing' do
    describe 'GET' do
      it 'routes to the :new action' do
        path = project_wiki_pages_new_path(project)

        expect(get('/' + path)).to route_to('projects/wiki_pages#new',
                                            namespace_id: project.namespace.to_param,
                                            project_id: project.to_param)
      end
    end
  end

  # Early versions of the wiki paths routed all wiki pages at
  # /wikis/:id - this test exists to guarantee that we support
  # old URIs that may be out there, saved in bookmarks, on other wikis, etc.
  describe 'legacy route support', type: 'request' do
    let(:path) { ::File.join(project_wikis_path(project), some_page_name) }

    before do
      get(path)
    end

    it 'routes to new wiki paths' do
      dest = project_wiki_path(project, wiki_page)

      expect(response).to redirect_to(dest)
    end

    context 'the page is nested in a directory' do
      let(:some_page_name) { 'some-dir/some-deep-dir/some-page' }
      let(:path) { ::File.join(project_wikis_path(project), some_page_name) }

      it 'still routes correctly' do
        dest = project_wiki_path(project, wiki_page)

        expect(response).to redirect_to(dest)
      end
    end

    context 'the user requested the old history path' do
      let(:some_page_name) { 'some-dir/some-deep-dir/some-page' }
      let(:path) { ::File.join(project_wikis_path(project), some_page_name, 'history') }

      it 'redirects to the new history path' do
        dest = project_wiki_history_path(project, wiki_page)

        expect(response).to redirect_to(dest)
      end
    end

    context 'the user requested the old edit path' do
      let(:some_page_name) { 'some-dir/some-deep-dir/some-page' }
      let(:path) { ::File.join(project_wikis_path(project), some_page_name, 'edit') }

      it 'redirects to the new history path' do
        dest = project_wiki_edit_path(project, wiki_page)

        expect(response).to redirect_to(dest)
      end
    end
  end
end
