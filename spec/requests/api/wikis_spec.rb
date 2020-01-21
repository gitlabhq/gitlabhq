# frozen_string_literal: true

require 'spec_helper'

# For every API endpoint we test 3 states of wikis:
# - disabled
# - enabled only for team members
# - enabled for everyone who has access
# Every state is tested for 3 user roles:
# - guest
# - developer
# - maintainer
# because they are 3 edge cases of using wiki pages.

describe API::Wikis do
  include WorkhorseHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group).tap { |g| g.add_owner(user) } }
  let(:project_wiki) { create(:project_wiki, project: project, user: user) }
  let(:payload) { { content: 'content', format: 'rdoc', title: 'title' } }
  let(:expected_keys_with_content) { %w(content format slug title) }
  let(:expected_keys_without_content) { %w(format slug title) }

  shared_examples_for 'returns list of wiki pages' do
    context 'when wiki has pages' do
      let!(:pages) do
        [create(:wiki_page, wiki: project_wiki, attrs: { title: 'page1', content: 'content of page1' }),
         create(:wiki_page, wiki: project_wiki, attrs: { title: 'page2.with.dot', content: 'content of page2' })]
      end

      it 'returns the list of wiki pages without content' do
        get api(url, user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.size).to eq(2)

        json_response.each_with_index do |page, index|
          expect(page.keys).to match_array(expected_keys_without_content)
          expect(page['slug']).to eq(pages[index].slug)
          expect(page['title']).to eq(pages[index].title)
        end
      end

      it 'returns the list of wiki pages with content' do
        get api(url, user), params: { with_content: 1 }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.size).to eq(2)

        json_response.each_with_index do |page, index|
          expect(page.keys).to match_array(expected_keys_with_content)
          expect(page['content']).to eq(pages[index].content)
          expect(page['slug']).to eq(pages[index].slug)
          expect(page['title']).to eq(pages[index].title)
        end
      end
    end

    it 'return the empty list of wiki pages' do
      get api(url, user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response.size).to eq(0)
    end
  end

  shared_examples_for 'returns wiki page' do
    it 'returns the wiki page' do
      expect(response).to have_gitlab_http_status(200)
      expect(json_response.size).to eq(4)
      expect(json_response.keys).to match_array(expected_keys_with_content)
      expect(json_response['content']).to eq(page.content)
      expect(json_response['slug']).to eq(page.slug)
      expect(json_response['title']).to eq(page.title)
    end
  end

  shared_examples_for 'creates wiki page' do
    it 'creates the wiki page' do
      post(api(url, user), params: payload)

      expect(response).to have_gitlab_http_status(201)
      expect(json_response.size).to eq(4)
      expect(json_response.keys).to match_array(expected_keys_with_content)
      expect(json_response['content']).to eq(payload[:content])
      expect(json_response['slug']).to eq(payload[:title].tr(' ', '-'))
      expect(json_response['title']).to eq(payload[:title])
      expect(json_response['rdoc']).to eq(payload[:rdoc])
    end

    [:title, :content].each do |part|
      it "responds with validation error on empty #{part}" do
        payload.delete(part)

        post(api(url, user), params: payload)

        expect(response).to have_gitlab_http_status(400)
        expect(json_response.size).to eq(1)
        expect(json_response['error']).to eq("#{part} is missing")
      end
    end
  end

  shared_examples_for 'updates wiki page' do
    it 'updates the wiki page' do
      put(api(url, user), params: payload)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response.size).to eq(4)
      expect(json_response.keys).to match_array(expected_keys_with_content)
      expect(json_response['content']).to eq(payload[:content])
      expect(json_response['slug']).to eq(payload[:title].tr(' ', '-'))
      expect(json_response['title']).to eq(payload[:title])
    end

    [:title, :content, :format].each do |part|
      it "updates with wiki with missing #{part}" do
        payload.delete(part)

        put(api(url, user), params: payload)

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end

  shared_examples_for '403 Forbidden' do
    it 'returns 403 Forbidden' do
      expect(response).to have_gitlab_http_status(403)
      expect(json_response.size).to eq(1)
      expect(json_response['message']).to eq('403 Forbidden')
    end
  end

  shared_examples_for '404 Wiki Page Not Found' do
    it 'returns 404 Wiki Page Not Found' do
      expect(response).to have_gitlab_http_status(404)
      expect(json_response.size).to eq(1)
      expect(json_response['message']).to eq('404 Wiki Page Not Found')
    end
  end

  shared_examples_for '404 Project Not Found' do
    it 'returns 404 Project Not Found' do
      expect(response).to have_gitlab_http_status(404)
      expect(json_response.size).to eq(1)
      expect(json_response['message']).to eq('404 Project Not Found')
    end
  end

  shared_examples_for '204 No Content' do
    it 'returns 204 No Content' do
      expect(response).to have_gitlab_http_status(204)
    end
  end

  shared_examples_for 'uploads wiki attachment' do
    it 'pushes attachment to the wiki repository' do
      allow(SecureRandom).to receive(:hex).and_return('fixed_hex')

      workhorse_post_with_file(api(url, user), file_key: :file, params: payload)

      expect(response).to have_gitlab_http_status(201)
      expect(json_response).to eq result_hash.deep_stringify_keys
    end

    it 'responds with validation error on empty file' do
      payload.delete(:file)

      post(api(url, user), params: payload)

      expect(response).to have_gitlab_http_status(400)
      expect(json_response.size).to eq(1)
      expect(json_response['error']).to eq('file is missing')
    end

    it 'responds with validation error on invalid temp file' do
      payload[:file] = { tempfile: '/etc/hosts' }

      post(api(url, user), params: payload)

      expect(response).to have_gitlab_http_status(400)
      expect(json_response.size).to eq(1)
      expect(json_response['error']).to eq('file is invalid')
    end

    it 'is backward compatible with regular multipart uploads' do
      allow(SecureRandom).to receive(:hex).and_return('fixed_hex')

      post(api(url, user), params: payload)

      expect(response).to have_gitlab_http_status(201)
      expect(json_response).to eq result_hash.deep_stringify_keys
    end
  end

  describe 'GET /projects/:id/wikis' do
    let(:url) { "/projects/#{project.id}/wikis" }

    context 'when wiki is disabled' do
      let(:project) { create(:project, :wiki_repo, :wiki_disabled) }

      context 'when user is guest' do
        before do
          get api(url)
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)

          get api(url, user)
        end

        include_examples '403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)

          get api(url, user)
        end

        include_examples '403 Forbidden'
      end
    end

    context 'when wiki is available only for team members' do
      let(:project) { create(:project, :wiki_repo, :wiki_private) }

      context 'when user is guest' do
        before do
          get api(url)
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'returns list of wiki pages'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'returns list of wiki pages'
      end
    end

    context 'when wiki is available for everyone with access' do
      let(:project) { create(:project, :wiki_repo) }

      context 'when user is guest' do
        before do
          get api(url)
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'returns list of wiki pages'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'returns list of wiki pages'
      end
    end
  end

  describe 'GET /projects/:id/wikis/:slug' do
    let(:page) { create(:wiki_page, wiki: project.wiki) }
    let(:url) { "/projects/#{project.id}/wikis/#{page.slug}" }

    context 'when wiki is disabled' do
      let(:project) { create(:project, :wiki_repo, :wiki_disabled) }

      context 'when user is guest' do
        before do
          get api(url)
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)

          get api(url, user)
        end

        include_examples '403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)

          get api(url, user)
        end

        include_examples '403 Forbidden'
      end
    end

    context 'when wiki is available only for team members' do
      let(:project) { create(:project, :wiki_repo, :wiki_private) }

      context 'when user is guest' do
        before do
          get api(url)
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
          get api(url, user)
        end

        include_examples 'returns wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          include_examples '404 Wiki Page Not Found'
        end
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)

          get api(url, user)
        end

        include_examples 'returns wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          include_examples '404 Wiki Page Not Found'
        end
      end
    end

    context 'when wiki is available for everyone with access' do
      let(:project) { create(:project, :wiki_repo) }

      context 'when user is guest' do
        before do
          get api(url)
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)

          get api(url, user)
        end

        include_examples 'returns wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          include_examples '404 Wiki Page Not Found'
        end
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)

          get api(url, user)
        end

        include_examples 'returns wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          include_examples '404 Wiki Page Not Found'
        end
      end
    end
  end

  describe 'POST /projects/:id/wikis' do
    let(:payload) { { title: 'title', content: 'content' } }
    let(:url) { "/projects/#{project.id}/wikis" }

    context 'when wiki is disabled' do
      let(:project) { create(:project, :wiki_disabled, :wiki_repo) }

      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
          post(api(url, user), params: payload)
        end

        include_examples '403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
          post(api(url, user), params: payload)
        end

        include_examples '403 Forbidden'
      end
    end

    context 'when wiki is available only for team members' do
      let(:project) { create(:project, :wiki_private, :wiki_repo) }

      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'creates wiki page'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'creates wiki page'
      end
    end

    context 'when wiki is available for everyone with access' do
      let(:project) { create(:project, :wiki_repo) }

      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'creates wiki page'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'creates wiki page'
      end
    end
  end

  describe 'PUT /projects/:id/wikis/:slug' do
    let(:page) { create(:wiki_page, wiki: project_wiki) }
    let(:payload) { { title: 'new title', content: 'new content' } }
    let(:url) { "/projects/#{project.id}/wikis/#{page.slug}" }

    context 'when wiki is disabled' do
      let(:project) { create(:project, :wiki_disabled, :wiki_repo) }

      context 'when user is guest' do
        before do
          put(api(url), params: payload)
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)

          put(api(url, user), params: payload)
        end

        include_examples '403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)

          put(api(url, user), params: payload)
        end

        include_examples '403 Forbidden'
      end
    end

    context 'when wiki is available only for team members' do
      let(:project) { create(:project, :wiki_private, :wiki_repo) }

      context 'when user is guest' do
        before do
          put(api(url), params: payload)
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'updates wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          before do
            put(api(url, user), params: payload)
          end

          include_examples '404 Wiki Page Not Found'
        end
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'updates wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          before do
            put(api(url, user), params: payload)
          end

          include_examples '404 Wiki Page Not Found'
        end
      end
    end

    context 'when wiki is available for everyone with access' do
      let(:project) { create(:project, :wiki_repo) }

      context 'when user is guest' do
        before do
          put(api(url), params: payload)
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'updates wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          before do
            put(api(url, user), params: payload)
          end

          include_examples '404 Wiki Page Not Found'
        end
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'updates wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          before do
            put(api(url, user), params: payload)
          end

          include_examples '404 Wiki Page Not Found'
        end
      end
    end

    context 'when wiki belongs to a group project' do
      let(:project) { create(:project, :wiki_repo, namespace: group) }

      include_examples 'updates wiki page'
    end
  end

  describe 'DELETE /projects/:id/wikis/:slug' do
    let(:page) { create(:wiki_page, wiki: project_wiki) }
    let(:url) { "/projects/#{project.id}/wikis/#{page.slug}" }

    context 'when wiki is disabled' do
      let(:project) { create(:project, :wiki_disabled, :wiki_repo) }

      context 'when user is guest' do
        before do
          delete(api(url))
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)

          delete(api(url, user))
        end

        include_examples '403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)

          delete(api(url, user))
        end

        include_examples '403 Forbidden'
      end
    end

    context 'when wiki is available only for team members' do
      let(:project) { create(:project, :wiki_private, :wiki_repo) }

      context 'when user is guest' do
        before do
          delete(api(url))
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)

          delete(api(url, user))
        end

        include_examples '403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)

          delete(api(url, user))
        end

        include_examples '204 No Content'
      end
    end

    context 'when wiki is available for everyone with access' do
      let(:project) { create(:project, :wiki_repo) }

      context 'when user is guest' do
        before do
          delete(api(url))
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)

          delete(api(url, user))
        end

        include_examples '403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)

          delete(api(url, user))
        end

        include_examples '204 No Content'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          include_examples '404 Wiki Page Not Found'
        end
      end
    end

    context 'when wiki belongs to a group project' do
      let(:project) { create(:project, :wiki_repo, namespace: group) }

      before do
        delete(api(url, user))
      end

      include_examples '204 No Content'
    end
  end

  describe 'POST /projects/:id/wikis/attachments' do
    let(:payload) { { file: fixture_file_upload('spec/fixtures/dk.png') } }
    let(:url) { "/projects/#{project.id}/wikis/attachments" }
    let(:file_path) { "#{Wikis::CreateAttachmentService::ATTACHMENT_PATH}/fixed_hex/dk.png" }
    let(:result_hash) do
      {
        file_name: 'dk.png',
        file_path: file_path,
        branch: 'master',
        link: {
          url: file_path,
          markdown: "![dk](#{file_path})"
        }
      }
    end

    context 'when wiki is disabled' do
      let(:project) { create(:project, :wiki_disabled, :wiki_repo) }

      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
          post(api(url, user), params: payload)
        end

        include_examples '403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
          post(api(url, user), params: payload)
        end

        include_examples '403 Forbidden'
      end
    end

    context 'when wiki is available only for team members' do
      let(:project) { create(:project, :wiki_private, :wiki_repo) }

      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'uploads wiki attachment'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'uploads wiki attachment'
      end
    end

    context 'when wiki is available for everyone with access' do
      let(:project) { create(:project, :wiki_repo) }

      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples '404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'uploads wiki attachment'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'uploads wiki attachment'
      end
    end
  end
end
