# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Release::Links, feature_category: :release_orchestration do
  include Ci::JobTokenScopeHelpers

  let_it_be_with_reload(:project) { create(:project, :repository, :private) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:non_project_member) { create(:user) }
  let_it_be(:commit) { create(:commit, project: project) }

  let!(:release) do
    create(:release, project: project, tag: 'v0.1', author: maintainer)
  end

  before_all do
    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)

    project.repository.add_tag(maintainer, 'v0.1', commit.id)
  end

  describe 'GET /projects/:id/releases/:tag_name/assets/links' do
    it_behaves_like 'enforcing job token policies', :read_releases do
      let_it_be(:user) { maintainer }
      let(:request) do
        get api("/projects/#{source_project.id}/releases/v0.1/assets/links"),
          params: { job_token: target_job.token }
      end
    end

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

      context 'when using JOB-TOKEN auth' do
        let(:job) { create(:ci_build, :running, user: maintainer, project: project) }

        it 'returns releases links' do
          get api("/projects/#{project.id}/releases/v0.1/assets/links", job_token: job.token)

          aggregate_failures "testing response" do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('release/links')
            expect(json_response.count).to eq(2)
          end
        end
      end
    end

    context 'when release does not exist' do
      let!(:release) {}

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
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        it 'allows the request' do
          get api("/projects/#{project.id}/releases/v0.1/assets/links", non_project_member)

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'and the releases are private' do
          before do
            project.project_feature.update!(releases_access_level: ProjectFeature::PRIVATE)
          end

          it_behaves_like '403 response' do
            let(:request) { get api("/projects/#{project.id}/releases/v0.1/assets/links", non_project_member) }
          end
        end
      end
    end
  end

  describe 'GET /projects/:id/releases/:tag_name/assets/links/:link_id' do
    let!(:release_link) { create(:release_link, release: release) }

    it_behaves_like 'enforcing job token policies', :read_releases do
      let_it_be(:user) { maintainer }
      let(:request) do
        get api("/projects/#{source_project.id}/releases/v0.1/assets/links/#{release_link.id}"),
          params: { job_token: target_job.token }
      end
    end

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

    context 'when using JOB-TOKEN auth' do
      let(:job) { create(:ci_build, :running, user: maintainer, project: project) }

      it 'returns releases link' do
        get api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", job_token: job.token)

        aggregate_failures "testing response" do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('release/link')
          expect(json_response['name']).to eq(release_link.name)
        end
      end
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

          expect(json_response['direct_asset_url']).to eq("http://localhost/#{project.full_path}/-/releases/#{release.tag}/downloads/bin/bigfile.exe")
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

    it_behaves_like 'enforcing job token policies', :admin_releases do
      let_it_be(:user) { maintainer }
      let(:request) do
        post api("/projects/#{source_project.id}/releases/v0.1/assets/links"),
          params: params.merge(job_token: target_job.token)
      end
    end

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

    context 'when using `direct_asset_path`' do
      before do
        params[:direct_asset_path] = params.delete(:filepath)
      end

      it 'creates a new release link successfully' do
        expect do
          post api("/projects/#{project.id}/releases/v0.1/assets/links", maintainer), params: params
        end.to change { Releases::Link.count }.by(1)

        release.reload

        expect(last_release_link.name).to eq('awesome-app.dmg')
        expect(last_release_link.filepath).to eq('/binaries/awesome-app.dmg')
        expect(last_release_link.url).to eq('https://example.com/download/awesome-app.dmg')
      end
    end

    context 'when using JOB-TOKEN auth' do
      let(:job) { create(:ci_build, :running, user: maintainer, project: project) }

      it 'creates a new release link' do
        expect do
          post api("/projects/#{project.id}/releases/v0.1/assets/links"), params: params.merge(job_token: job.token)
        end.to change { Releases::Link.count }.by(1)

        release.reload

        aggregate_failures "testing response" do
          expect(response).to have_gitlab_http_status(:created)
          expect(last_release_link.name).to eq('awesome-app.dmg')
          expect(last_release_link.filepath).to eq('/binaries/awesome-app.dmg')
          expect(last_release_link.url).to eq('https://example.com/download/awesome-app.dmg')
        end
      end
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
          post api("/projects/#{project.id}/releases/v0.1/assets/links", maintainer), params: params
        end
      end
    end

    context 'when user is a reporter' do
      it_behaves_like '403 response' do
        let(:request) do
          post api("/projects/#{project.id}/releases/v0.1/assets/links", reporter), params: params
        end
      end
    end

    context 'when user is not a project member' do
      it 'forbids the request' do
        post api("/projects/#{project.id}/releases/v0.1/assets/links", non_project_member), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'forbids the request' do
          post api("/projects/#{project.id}/releases/v0.1/assets/links", non_project_member), params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when the same link already exists' do
      before do
        create(
          :release_link,
          release: release,
          name: 'awesome-app.dmg',
          url: 'https://example.com/download/awesome-app.dmg'
        )
      end

      it_behaves_like '400 response' do
        let(:request) do
          post api("/projects/#{project.id}/releases/v0.1/assets/links", maintainer), params: params
        end
      end
    end
  end

  describe 'PUT /projects/:id/releases/:tag_name/assets/links/:link_id' do
    let(:params) { { name: 'awesome-app.msi' } }
    let!(:release_link) { create(:release_link, release: release) }

    it_behaves_like 'enforcing job token policies', :admin_releases do
      let_it_be(:user) { maintainer }
      let(:request) do
        put api("/projects/#{source_project.id}/releases/v0.1/assets/links/#{release_link.id}"),
          params: params.merge(job_token: target_job.token)
      end
    end

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

    context 'when params are invalid' do
      it 'returns 400 error' do
        put api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", maintainer),
          params: params.merge(url: 'wrong_url')

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when using `direct_asset_path`' do
      it 'updates the release link' do
        put api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", maintainer),
          params: params.merge(direct_asset_path: '/binaries/awesome-app.msi')

        expect(json_response['direct_asset_url'])
          .to eq("http://localhost/#{project.full_path}/-/releases/#{release.tag}/downloads/binaries/awesome-app.msi")
      end
    end

    context 'when using JOB-TOKEN auth' do
      let(:job) { create(:ci_build, :running, user: maintainer, project: project) }

      it 'updates the release link' do
        put api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}"), params: params.merge(job_token: job.token)

        aggregate_failures "testing response" do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('release/link')
          expect(json_response['name']).to eq('awesome-app.msi')
        end
      end
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
      let!(:release_link) {}

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

    it_behaves_like 'enforcing job token policies', :admin_releases do
      let_it_be(:user) { maintainer }
      let(:request) do
        delete api("/projects/#{source_project.id}/releases/v0.1/assets/links/#{release_link.id}"),
          params: { job_token: target_job.token }
      end
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

    context 'when using JOB-TOKEN auth' do
      let(:job) { create(:ci_build, :running, user: maintainer, project: project) }

      it 'deletes the release link' do
        expect do
          delete api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", job_token: job.token)
        end.to change { Releases::Link.count }.by(-1)

        aggregate_failures "testing response" do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('release/link')
        end
      end
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

    context 'when destroy process fails' do
      before do
        allow_next_instance_of(::Releases::Links::DestroyService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'error'))
        end
      end

      it_behaves_like '400 response' do
        let(:message) { 'error' }
        let(:request) do
          delete api("/projects/#{project.id}/releases/v0.1/assets/links/#{release_link.id}", maintainer)
        end
      end
    end

    context 'when there are no corresponding release link' do
      let!(:release_link) {}

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
