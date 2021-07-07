# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Release::Links do
  let(:project) { create(:project, :repository, :private) }
  let(:maintainer) { create(:user) }
  let(:developer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:non_project_member) { create(:user) }
  let(:commit) { create(:commit, project: project) }

  let!(:release) do
    create(:release,
           project: project,
           tag: 'v0.1',
           author: maintainer)
  end

  before do
    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)

    project.repository.add_tag(maintainer, 'v0.1', commit.id)
  end

  describe 'GET /projects/:id/releases/:tag_name/assets/links' do
    context 'when there are two release links' do
      let!(:release_link_1) { create(:release_link, release: release, created_at: 2.days.ago) }
      let!(:release_link_2) { create(:release_link, release: release, created_at: 1.day.ago) }

      it 'returns 200 HTTP status' do
        get api("/projects/#{project.id}/releases/v0.1/assets/links", maintainer)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns release links ordered by created_at' do
        get api("/projects/#{project.id}/releases/v0.1/assets/links", maintainer)

        expect(json_response.count).to eq(2)
        expect(json_response.first['name']).to eq(release_link_2.name)
        expect(json_response.second['name']).to eq(release_link_1.name)
      end

      it 'matches response schema' do
        get api("/projects/#{project.id}/releases/v0.1/assets/links", maintainer)

        expect(response).to match_response_schema('release/links')
      end
    end

    context 'when release does not exist' do
      let!(:release) { }

      it_behaves_like '404 response' do
        let(:request) { get api("/projects/#{project.id}/releases/v0.1/assets/links", maintainer) }
        let(:message) { '404 Not found' }
      end
    end

    context 'when user is not a project member' do
      it_behaves_like '404 response' do
        let(:request) { get api("/projects/#{project.id}/releases/v0.1/assets/links", non_project_member) }
        let(:message) { '404 Project Not Found' }
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'allows the request' do
          get api("/projects/#{project.id}/releases/v0.1/assets/links", non_project_member)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when project is public and the repository is private' do
        let(:project) { create(:project, :repository, :public, :repository_private) }

        it_behaves_like '403 response' do
          let(:request) { get api("/projects/#{project.id}/releases/v0.1/assets/links", non_project_member) }
        end

        context 'when the release does not exists' do
          let!(:release) { }

          it_behaves_like '403 response' do
            let(:request) { get api("/projects/#{project.id}/releases/v0.1/assets/links", non_project_member) }
          end
        end
      end
    end
  end

  describe 'GET /projects/:id/releases/:tag_name/assets/links/:link_id' do
    let!(:release_link) { create(:release_link, release: release) }

    it 'returns 200 HTTP status' do
      get api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", maintainer)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns a link entry' do
      get api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", maintainer)

      expect(json_response['name']).to eq(release_link.name)
      expect(json_response['url']).to eq(release_link.url)
    end

    it 'matches response schema' do
      get api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", maintainer)

      expect(response).to match_response_schema('release/link')
    end

    context 'when specified tag is not found in the project' do
      it_behaves_like '404 response' do
        let(:request) { get api("/projects/#{project.id}/releases/non_existing_tag/assets/links/#{release_link.id}", maintainer) }
      end
    end

    context 'when user is not a project member' do
      it_behaves_like '404 response' do
        let(:request) { get api("/projects/#{project.id}/releases/non_existing_tag/assets/links/#{release_link.id}", non_project_member) }
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'allows the request' do
          get api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", non_project_member)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    describe '#direct_asset_url' do
      let!(:link) { create(:release_link, release: release, url: url, filepath: filepath) }
      let(:url) { 'https://google.com/-/jobs/140463678/artifacts/download' }

      context 'when filepath is provided' do
        let(:filepath) { '/bin/bigfile.exe' }

        specify do
          get api("/projects/#{project.id}/releases/v0.1/assets/links/#{link.id}", maintainer)

          expect(json_response['direct_asset_url']).to eq("http://localhost/#{project.namespace.path}/#{project.name}/-/releases/#{release.tag}/downloads/bin/bigfile.exe")
        end
      end

      context 'when filepath is not provided' do
        let(:filepath) { nil }

        specify do
          get api("/projects/#{project.id}/releases/v0.1/assets/links/#{link.id}", maintainer)

          expect(json_response['direct_asset_url']).to eq(url)
        end
      end
    end
  end

  describe 'POST /projects/:id/releases/:tag_name/assets/links' do
    let(:params) do
      {
        name: 'awesome-app.dmg',
        filepath: '/binaries/awesome-app.dmg',
        url: 'https://example.com/download/awesome-app.dmg'
      }
    end

    let(:last_release_link) { release.links.last }

    it 'accepts the request' do
      post api("/projects/#{project.id}/releases/v0.1/assets/links", maintainer), params: params

      expect(response).to have_gitlab_http_status(:created)
    end

    it 'creates a new release' do
      expect do
        post api("/projects/#{project.id}/releases/v0.1/assets/links", maintainer), params: params
      end.to change { Releases::Link.count }.by(1)

      release.reload
      expect(last_release_link.name).to eq('awesome-app.dmg')
      expect(last_release_link.filepath).to eq('/binaries/awesome-app.dmg')
      expect(last_release_link.url).to eq('https://example.com/download/awesome-app.dmg')
    end

    it 'matches response schema' do
      post api("/projects/#{project.id}/releases/v0.1/assets/links", maintainer), params: params

      expect(response).to match_response_schema('release/link')
    end

    context 'with protected tag' do
      context 'when user has access to the protected tag' do
        let!(:protected_tag) { create(:protected_tag, :developers_can_create, name: '*', project: project) }

        it 'accepts the request' do
          post api("/projects/#{project.id}/releases/v0.1/assets/links", developer), params: params

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'when user does not have access to the protected tag' do
        let!(:protected_tag) { create(:protected_tag, :maintainers_can_create, name: '*', project: project) }

        it 'forbids the request' do
          post api("/projects/#{project.id}/releases/v0.1/assets/links", developer), params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when name is empty' do
      let(:params) do
        {
          name: '',
          url: 'https://example.com/download/awesome-app.dmg'
        }
      end

      it_behaves_like '400 response' do
        let(:request) do
          post api("/projects/#{project.id}/releases/v0.1/assets/links", maintainer),
               params: params
        end
      end
    end

    context 'when user is a reporter' do
      it_behaves_like '403 response' do
        let(:request) do
          post api("/projects/#{project.id}/releases/v0.1/assets/links", reporter),
               params: params
        end
      end
    end

    context 'when user is not a project member' do
      it 'forbids the request' do
        post api("/projects/#{project.id}/releases/v0.1/assets/links", non_project_member),
             params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'forbids the request' do
          post api("/projects/#{project.id}/releases/v0.1/assets/links", non_project_member),
               params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when the same link already exists' do
      before do
        create(:release_link,
               release: release,
               name: 'awesome-app.dmg',
               url: 'https://example.com/download/awesome-app.dmg')
      end

      it_behaves_like '400 response' do
        let(:request) do
          post api("/projects/#{project.id}/releases/v0.1/assets/links", maintainer),
               params: params
        end
      end
    end
  end

  describe 'PUT /projects/:id/releases/:tag_name/assets/links/:link_id' do
    let(:params) { { name: 'awesome-app.msi' } }
    let!(:release_link) { create(:release_link, release: release) }

    it 'accepts the request' do
      put api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", maintainer),
          params: params

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'updates the name' do
      put api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", maintainer),
          params: params

      expect(json_response['name']).to eq('awesome-app.msi')
    end

    it 'does not update the url' do
      put api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", maintainer),
          params: params

      expect(json_response['url']).to eq(release_link.url)
    end

    it 'matches response schema' do
      put api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", maintainer),
          params: params

      expect(response).to match_response_schema('release/link')
    end

    context 'with protected tag' do
      context 'when user has access to the protected tag' do
        let!(:protected_tag) { create(:protected_tag, :developers_can_create, name: '*', project: project) }

        it 'accepts the request' do
          put api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", developer), params: params

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when user does not have access to the protected tag' do
        let!(:protected_tag) { create(:protected_tag, :maintainers_can_create, name: '*', project: project) }

        it 'forbids the request' do
          put api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", developer), params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when params is empty' do
      let(:params) { {} }

      it 'does not allow the request' do
        put api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", maintainer),
            params: params

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when there are no corresponding release link' do
      let!(:release_link) { }

      it_behaves_like '404 response' do
        let(:request) do
          put api("/projects/#{project.id}/releases/v0.1/assets/links/1", maintainer),
              params: params
        end
      end
    end

    context 'when user is a reporter' do
      it_behaves_like '403 response' do
        let(:request) do
          put api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", reporter),
              params: params
        end
      end
    end

    context 'when user is not a project member' do
      it_behaves_like '404 response' do
        let(:request) do
          put api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", non_project_member),
              params: params
        end
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it_behaves_like '403 response' do
          let(:request) do
            put api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", non_project_member),
                params: params
          end
        end
      end
    end
  end

  describe 'DELETE /projects/:id/releases/:tag_name/assets/links/:link_id' do
    let!(:release_link) do
      create(:release_link, release: release)
    end

    it 'accepts the request' do
      delete api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", maintainer)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'destroys the release link' do
      expect do
        delete api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", maintainer)
      end.to change { Releases::Link.count }.by(-1)
    end

    it 'matches response schema' do
      delete api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", maintainer)

      expect(response).to match_response_schema('release/link')
    end

    context 'with protected tag' do
      context 'when user has access to the protected tag' do
        let!(:protected_tag) { create(:protected_tag, :developers_can_create, name: '*', project: project) }

        it 'accepts the request' do
          delete api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", developer)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when user does not have access to the protected tag' do
        let!(:protected_tag) { create(:protected_tag, :maintainers_can_create, name: '*', project: project) }

        it 'forbids the request' do
          delete api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", developer)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when there are no corresponding release link' do
      let!(:release_link) { }

      it_behaves_like '404 response' do
        let(:request) do
          delete api("/projects/#{project.id}/releases/v0.1/assets/links/1", maintainer)
        end
      end
    end

    context 'when user is a reporter' do
      it_behaves_like '403 response' do
        let(:request) do
          delete api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", reporter)
        end
      end
    end

    context 'when user is not a project member' do
      it_behaves_like '404 response' do
        let(:request) do
          delete api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", non_project_member)
        end
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it_behaves_like '403 response' do
          let(:request) do
            delete api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", non_project_member)
          end
        end
      end
    end
  end
end
