require 'spec_helper'

describe API::Releases do
  let(:project) { create(:project, :repository, :private) }
  let(:maintainer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:non_project_member) { create(:user) }
  let(:commit) { create(:commit, project: project) }

  before do
    project.add_maintainer(maintainer)
    project.add_reporter(reporter)

    project.repository.add_tag(maintainer, 'v0.1', commit.id)
    project.repository.add_tag(maintainer, 'v0.2', commit.id)
  end

  describe 'GET /projects/:id/releases' do
    context 'when there are two releases' do
      let!(:release_1) do
        create(:release,
               project: project,
               tag: 'v0.1',
               author: maintainer,
               created_at: 2.days.ago)
      end

      let!(:release_2) do
        create(:release,
               project: project,
               tag: 'v0.2',
               author: maintainer,
               created_at: 1.day.ago)
      end

      it 'returns 200 HTTP status' do
        get api("/projects/#{project.id}/releases", maintainer)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns releases ordered by created_at' do
        get api("/projects/#{project.id}/releases", maintainer)

        expect(json_response.count).to eq(2)
        expect(json_response.first['tag_name']).to eq(release_2.tag)
        expect(json_response.second['tag_name']).to eq(release_1.tag)
      end

      it 'matches response schema' do
        get api("/projects/#{project.id}/releases", maintainer)

        expect(response).to match_response_schema('releases')
      end
    end

    context 'when tag does not exist in git repository' do
      let!(:release) { create(:release, project: project, tag: 'v1.1.5') }

      it 'returns the tag' do
        get api("/projects/#{project.id}/releases", maintainer)

        expect(json_response.count).to eq(1)
        expect(json_response.first['tag_name']).to eq('v1.1.5')
        expect(release).to be_tag_missing
      end
    end

    context 'when user is not a project member' do
      it 'cannot find the project' do
        get api("/projects/#{project.id}/releases", non_project_member)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'allows the request' do
          get api("/projects/#{project.id}/releases", non_project_member)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(releases_page: false)
      end

      it 'cannot find the API' do
        get api("/projects/#{project.id}/releases", maintainer)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/releases/:tag_name' do
    context 'when there is a release' do
      let!(:release) do
        create(:release,
               project: project,
               tag: 'v0.1',
               sha: commit.id,
               author: maintainer,
               description: 'This is v0.1')
      end

      it 'returns 200 HTTP status' do
        get api("/projects/#{project.id}/releases/v0.1", maintainer)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns a release entry' do
        get api("/projects/#{project.id}/releases/v0.1", maintainer)

        expect(json_response['tag_name']).to eq(release.tag)
        expect(json_response['description']).to eq('This is v0.1')
        expect(json_response['author']['name']).to eq(maintainer.name)
        expect(json_response['commit']['id']).to eq(commit.id)
      end

      it 'matches response schema' do
        get api("/projects/#{project.id}/releases/v0.1", maintainer)

        expect(response).to match_response_schema('release')
      end
    end

    context 'when specified tag is not found in the project' do
      it 'cannot find the release entry' do
        get api("/projects/#{project.id}/releases/non_exist_tag", maintainer)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is not a project member' do
      let!(:release) { create(:release, tag: 'v0.1', project: project) }

      it 'cannot find the project' do
        get api("/projects/#{project.id}/releases/v0.1", non_project_member)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'allows the request' do
          get api("/projects/#{project.id}/releases/v0.1", non_project_member)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(releases_page: false)
      end

      it 'cannot find the API' do
        get api("/projects/#{project.id}/releases/v0.1", maintainer)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /projects/:id/releases' do
    let(:params) do
      {
        name: 'New release',
        tag_name: 'v0.1',
        description: 'Super nice release'
      }
    end

    it 'accepts the request' do
      post api("/projects/#{project.id}/releases", maintainer), params: params

      expect(response).to have_gitlab_http_status(:created)
    end

    it 'creates a new release' do
      expect do
        post api("/projects/#{project.id}/releases", maintainer), params: params
      end.to change { Release.count }.by(1)

      expect(project.releases.last.name).to eq('New release')
      expect(project.releases.last.tag).to eq('v0.1')
      expect(project.releases.last.description).to eq('Super nice release')
    end

    context 'when description is empty' do
      let(:params) do
        {
          name: 'New release',
          tag_name: 'v0.1',
          description: ''
        }
      end

      it 'returns an error as validation failure' do
        expect do
          post api("/projects/#{project.id}/releases", maintainer), params: params
        end.not_to change { Release.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message'])
          .to eq("Validation failed: Description can't be blank")
      end
    end

    it 'matches response schema' do
      post api("/projects/#{project.id}/releases", maintainer), params: params

      expect(response).to match_response_schema('release')
    end

    it 'does not create a new tag' do
      expect do
        post api("/projects/#{project.id}/releases", maintainer), params: params
      end.not_to change { Project.find_by_id(project.id).repository.tag_count }
    end

    context 'when user is a reporter' do
      it 'forbids the request' do
        post api("/projects/#{project.id}/releases", reporter), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is not a project member' do
      it 'forbids the request' do
        post api("/projects/#{project.id}/releases", non_project_member),
             params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'forbids the request' do
          post api("/projects/#{project.id}/releases", non_project_member),
               params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when tag does not exist in git repository' do
      let(:params) do
        {
          name: 'Android ~ Ice Cream Sandwich ~',
          tag_name: tag_name,
          description: 'Android 4.0–4.0.4 "Ice Cream Sandwich" is the ninth' \
                       'version of the Android mobile operating system developed' \
                       'by Google.',
          ref: 'master'
        }
      end

      let(:tag_name) { 'v4.0' }

      it 'creates a new tag' do
        expect do
          post api("/projects/#{project.id}/releases", maintainer), params: params
        end.to change { Project.find_by_id(project.id).repository.tag_count }.by(1)

        expect(project.repository.find_tag('v4.0').dereferenced_target.id)
          .to eq(project.repository.commit('master').id)
      end

      it 'creates a new release' do
        expect do
          post api("/projects/#{project.id}/releases", maintainer), params: params
        end.to change { Release.count }.by(1)

        expect(project.releases.last.name).to eq('Android ~ Ice Cream Sandwich ~')
        expect(project.releases.last.tag).to eq('v4.0')
        expect(project.releases.last.description).to eq(
          'Android 4.0–4.0.4 "Ice Cream Sandwich" is the ninth' \
          'version of the Android mobile operating system developed' \
          'by Google.')
      end

      context 'when tag name is HEAD' do
        let(:tag_name) { 'HEAD' }

        it 'returns an error as failure on tag creation' do
          post api("/projects/#{project.id}/releases", maintainer), params: params

          expect(response).to have_gitlab_http_status(:internal_server_error)
          expect(json_response['message']).to eq('Tag name invalid')
        end
      end

      context 'when tag name is empty' do
        let(:tag_name) { '' }

        it 'returns an error as failure on tag creation' do
          post api("/projects/#{project.id}/releases", maintainer), params: params

          expect(response).to have_gitlab_http_status(:internal_server_error)
          expect(json_response['message']).to eq('Tag name invalid')
        end
      end
    end

    context 'when release already exists' do
      before do
        create(:release, project: project, tag: 'v0.1', name: 'New release')
      end

      it 'returns an error as conflicted request' do
        post api("/projects/#{project.id}/releases", maintainer), params: params

        expect(response).to have_gitlab_http_status(:conflict)
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(releases_page: false)
      end

      it 'cannot find the API' do
        post api("/projects/#{project.id}/releases", maintainer), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PUT /projects/:id/releases/:tag_name' do
    let(:params) { { description: 'Best release ever!' } }

    let!(:release) do
      create(:release,
             project: project,
             tag: 'v0.1',
             name: 'New release',
             description: 'Super nice release')
    end

    it 'accepts the request' do
      put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'updates the description' do
      put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params

      expect(project.releases.last.description).to eq('Best release ever!')
    end

    it 'does not change other attributes' do
      put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params

      expect(project.releases.last.tag).to eq('v0.1')
      expect(project.releases.last.name).to eq('New release')
    end

    it 'matches response schema' do
      put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params

      expect(response).to match_response_schema('release')
    end

    context 'when user tries to update sha' do
      let(:params) { { sha: 'xxx' } }

      it 'does not allow the request' do
        put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when params is empty' do
      let(:params) { {} }

      it 'does not allow the request' do
        put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when there are no corresponding releases' do
      let!(:release) { }

      it 'forbids the request' do
        put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is a reporter' do
      it 'forbids the request' do
        put api("/projects/#{project.id}/releases/v0.1", reporter), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is not a project member' do
      it 'forbids the request' do
        put api("/projects/#{project.id}/releases/v0.1", non_project_member),
             params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'forbids the request' do
          put api("/projects/#{project.id}/releases/v0.1", non_project_member),
               params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(releases_page: false)
      end

      it 'cannot find the API' do
        put api("/projects/#{project.id}/releases/v0.1", non_project_member),
          params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /projects/:id/releases/:tag_name' do
    let!(:release) do
      create(:release,
             project: project,
             tag: 'v0.1',
             name: 'New release',
             description: 'Super nice release')
    end

    it 'accepts the request' do
      delete api("/projects/#{project.id}/releases/v0.1", maintainer)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'destroys the release' do
      expect do
        delete api("/projects/#{project.id}/releases/v0.1", maintainer)
      end.to change { Release.count }.by(-1)
    end

    it 'does not remove a tag in repository' do
      expect do
        delete api("/projects/#{project.id}/releases/v0.1", maintainer)
      end.not_to change { Project.find_by_id(project.id).repository.tag_count }
    end

    it 'matches response schema' do
      delete api("/projects/#{project.id}/releases/v0.1", maintainer)

      expect(response).to match_response_schema('release')
    end

    context 'when there are no corresponding releases' do
      let!(:release) { }

      it 'forbids the request' do
        delete api("/projects/#{project.id}/releases/v0.1", maintainer)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is a reporter' do
      it 'forbids the request' do
        delete api("/projects/#{project.id}/releases/v0.1", reporter)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is not a project member' do
      it 'forbids the request' do
        delete api("/projects/#{project.id}/releases/v0.1", non_project_member)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'forbids the request' do
          delete api("/projects/#{project.id}/releases/v0.1", non_project_member)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(releases_page: false)
      end

      it 'cannot find the API' do
        delete api("/projects/#{project.id}/releases/v0.1", non_project_member)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
