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

RSpec.describe API::Wikis, feature_category: :wiki do
  include WorkhorseHelpers
  include AfterNextHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, owners: user) }
  let_it_be(:group_project) { create(:project, :wiki_repo, namespace: group) }

  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:project_wiki_disabled) do
    create(:project, :wiki_repo, :wiki_disabled).tap do |project|
      project.add_developer(developer)
      project.add_maintainer(maintainer)
    end
  end

  let(:project_wiki) { create(:project_wiki, project: project, user: user) }
  let(:payload) { { content: 'content', format: 'rdoc', title: 'title' } }
  let(:expected_keys_with_content) { %w[content format slug title encoding front_matter] }
  let(:expected_keys_without_content) { %w[format slug title] }
  let(:wiki) { project_wiki }

  shared_examples_for 'wiki API 404 Project Not Found' do
    include_examples 'wiki API 404 Not Found', 'Project'
  end

  describe 'GET /projects/:id/wikis' do
    let(:url) { "/projects/#{project.id}/wikis" }

    context 'when wiki is disabled' do
      let(:project) { project_wiki_disabled }

      context 'when user is guest' do
        before do
          get api(url)
        end

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          get api(url, developer)
        end

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          get api(url, maintainer)
        end

        include_examples 'wiki API 403 Forbidden'
      end
    end

    context 'when wiki is available only for team members' do
      let(:project) { create(:project, :wiki_repo, :wiki_private) }

      context 'when user is guest' do
        before do
          get api(url)
        end

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'wikis API returns list of wiki pages'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'wikis API returns list of wiki pages'
      end
    end

    context 'when wiki is available for everyone with access' do
      let(:project) { create(:project, :wiki_repo) }

      context 'when user is guest' do
        before do
          get api(url)
        end

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'wikis API returns list of wiki pages'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'wikis API returns list of wiki pages'
      end
    end
  end

  describe 'GET /projects/:id/wikis/:slug' do
    let(:page) { create(:wiki_page, wiki: project.wiki) }
    let(:url) { "/projects/#{project.id}/wikis/#{page.slug}" }
    let(:params) { {} }

    subject(:request) { get api(url, user), params: params }

    context 'when wiki is disabled' do
      let(:project) { project_wiki_disabled }

      before do
        request
      end

      context 'when user is guest' do
        let(:user) { nil }

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        let(:user) { developer }

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        let(:user) { maintainer }

        include_examples 'wiki API 403 Forbidden'
      end
    end

    context 'when wiki is available only for team members' do
      let_it_be_with_reload(:project) { create(:project, :wiki_repo, :wiki_private) }

      context 'when user is guest' do
        before do
          request
        end

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'wikis API returns wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          before do
            request
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'wikis API returns wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          before do
            request
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end
    end

    context 'when wiki is available for everyone with access' do
      let_it_be_with_reload(:project) { create(:project, :wiki_repo) }

      context 'when user is guest' do
        let(:user) { nil }

        before do
          request
        end

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'wikis API returns wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          before do
            request
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'wikis API returns wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          before do
            request
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end

      context 'when content contains a reference' do
        let(:issue) { create(:issue, project: project) }
        let(:params) { { render_html: true } }
        let(:page) { create(:wiki_page, wiki: project.wiki, title: 'page_with_ref', content: issue.to_reference) }
        let(:expected_content) { %r{<a href=".*#{issue.iid}".*>#{issue.to_reference}</a>} }

        before do
          project.add_developer(user)

          request
        end

        it 'expands the reference in the content' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['content']).to match(expected_content)
        end
      end
    end
  end

  describe 'POST /projects/:id/wikis' do
    let(:payload) { { title: 'title', content: 'content' } }
    let(:url) { "/projects/#{project.id}/wikis" }

    context 'when wiki is disabled' do
      let(:project) { project_wiki_disabled }

      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          post(api(url, developer), params: payload)
        end

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          post(api(url, maintainer), params: payload)
        end

        include_examples 'wiki API 403 Forbidden'
      end
    end

    context 'when wiki is available only for team members' do
      let(:project) { create(:project, :wiki_private, :wiki_repo) }

      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'wikis API creates wiki page'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'wikis API creates wiki page'
      end
    end

    context 'when wiki is available for everyone with access' do
      let(:project) { create(:project, :wiki_repo) }

      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'wikis API creates wiki page'

        context "with front matter title" do
          let(:payload) { { title: 'title', front_matter: { "title" => "title in front matter" }, content: 'content' } }

          it "save front matter" do
            post(api(url, user), params: payload)

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['front_matter']).to eq(payload[:front_matter])
            expect(json_response['content']).to include(payload[:front_matter]["title"])
          end
        end
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'wikis API creates wiki page'
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

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)

          put(api(url, user), params: payload)
        end

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)

          put(api(url, user), params: payload)
        end

        include_examples 'wiki API 403 Forbidden'
      end
    end

    context 'when wiki is available only for team members' do
      let(:project) { create(:project, :wiki_private, :wiki_repo) }

      context 'when user is guest' do
        before do
          put(api(url), params: payload)
        end

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'wikis API updates wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          before do
            put(api(url, user), params: payload)
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'wikis API updates wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          before do
            put(api(url, user), params: payload)
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end
    end

    context 'when wiki is available for everyone with access' do
      let(:project) { create(:project, :wiki_repo) }

      context 'when user is guest' do
        before do
          put(api(url), params: payload)
        end

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'wikis API updates wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          before do
            put(api(url, user), params: payload)
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end

        context "with front matter title" do
          let(:payload) do
            { title: 'new title', front_matter: { "title" => "title in front matter" }, content: 'new content' }
          end

          it "save front matter" do
            put(api(url, user), params: payload)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['front_matter']).to eq(payload[:front_matter])
            expect(json_response['content']).to include(payload[:front_matter]["title"])
          end
        end
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'wikis API updates wiki page'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          before do
            put(api(url, user), params: payload)
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end
    end

    context 'when wiki belongs to a group project' do
      let(:project) { group_project }

      include_examples 'wikis API updates wiki page'
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

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)

          delete(api(url, user))
        end

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)

          delete(api(url, user))
        end

        include_examples 'wiki API 403 Forbidden'
      end
    end

    context 'when wiki is available only for team members' do
      let(:project) { create(:project, :wiki_private, :wiki_repo) }

      context 'when user is guest' do
        before do
          delete(api(url))
        end

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)

          delete(api(url, user))
        end

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)

          delete(api(url, user))
        end

        include_examples 'wiki API 204 No Content'
      end
    end

    context 'when wiki is available for everyone with access' do
      let(:project) { create(:project, :wiki_repo) }

      context 'when user is guest' do
        before do
          delete(api(url))
        end

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)

          delete(api(url, user))
        end

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)

          delete(api(url, user))
        end

        include_examples 'wiki API 204 No Content'

        context 'when page is not existing' do
          let(:url) { "/projects/#{project.id}/wikis/unknown" }

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end

      context 'when there is an error deleting the page' do
        it 'returns 422' do
          project.add_maintainer(user)

          allow_next(WikiPages::DestroyService, current_user: user, container: project)
            .to receive(:execute).and_return(ServiceResponse.error(message: 'foo'))

          delete(api(url, user))

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq 'foo'
        end
      end
    end

    context 'when wiki belongs to a group project' do
      let(:project) { create(:project, :wiki_repo, namespace: group) }

      before do
        delete(api(url, user))
      end

      include_examples 'wiki API 204 No Content'
    end
  end

  describe 'POST /projects/:id/wikis/attachments' do
    let(:payload) { { file: fixture_file_upload('spec/fixtures/dk.png') } }
    let(:url) { "/projects/#{project.id}/wikis/attachments" }
    let(:file_path) { "#{Wikis::CreateAttachmentService::ATTACHMENT_PATH}/fixed_hex/dk.png" }
    let(:branch) { wiki.default_branch }
    let(:result_hash) do
      {
        file_name: 'dk.png',
        file_path: file_path,
        branch: branch,
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

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
          post(api(url, user), params: payload)
        end

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
          post(api(url, user), params: payload)
        end

        include_examples 'wiki API 403 Forbidden'
      end
    end

    context 'when wiki is available only for team members' do
      let(:project) { create(:project, :wiki_private, :wiki_repo) }

      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'wiki API uploads wiki attachment'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'wiki API uploads wiki attachment'
      end
    end

    context 'when wiki is available for everyone with access' do
      let(:project) { create(:project, :wiki_repo) }

      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples 'wiki API 404 Project Not Found'
      end

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        include_examples 'wiki API uploads wiki attachment'
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        include_examples 'wiki API uploads wiki attachment'
      end
    end
  end
end
