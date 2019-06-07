require 'spec_helper'

describe API::Releases do
  let(:project) { create(:project, :repository, :private) }
  let(:maintainer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:guest) { create(:user) }
  let(:non_project_member) { create(:user) }
  let(:commit) { create(:commit, project: project) }

  before do
    project.add_maintainer(maintainer)
    project.add_reporter(reporter)
    project.add_guest(guest)

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

        expect(response).to match_response_schema('public_api/v4/releases')
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

    context 'when user is a guest' do
      let!(:release) do
        create(:release,
               project: project,
               tag: 'v0.1',
               author: maintainer,
               created_at: 2.days.ago)
      end

      it 'responds 200 OK' do
        get api("/projects/#{project.id}/releases", guest)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it "does not expose tag, commit and source code" do
        get api("/projects/#{project.id}/releases", guest)

        expect(response).to match_response_schema('public_api/v4/release/releases_for_guest')
        expect(json_response[0]['assets']['count']).to eq(release.links.count)
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'responds 200 OK' do
          get api("/projects/#{project.id}/releases", guest)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it "exposes tag, commit and source code" do
          get api("/projects/#{project.id}/releases", guest)

          expect(response).to match_response_schema('public_api/v4/releases')
          expect(json_response[0]['assets']['count']).to eq(release.links.count + release.sources.count)
        end
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
        expect(json_response['assets']['count']).to eq(4)
      end

      it 'matches response schema' do
        get api("/projects/#{project.id}/releases/v0.1", maintainer)

        expect(response).to match_response_schema('public_api/v4/release')
      end

      it 'contains source information as assets' do
        get api("/projects/#{project.id}/releases/v0.1", maintainer)

        expect(json_response['assets']['sources'].map { |h| h['format'] })
          .to match_array(release.sources.map(&:format))
        expect(json_response['assets']['sources'].map { |h| h['url'] })
          .to match_array(release.sources.map(&:url))
      end

      context "when release description contains confidential issue's link" do
        let(:confidential_issue) do
          create(:issue,
                 :confidential,
                 project: project,
                 title: 'A vulnerability')
        end

        let!(:release) do
          create(:release,
                 project: project,
                 tag: 'v0.1',
                 sha: commit.id,
                 author: maintainer,
                 description: "This is confidential #{confidential_issue.to_reference}")
        end

        it "does not expose confidential issue's title" do
          get api("/projects/#{project.id}/releases/v0.1", maintainer)

          expect(json_response['description_html']).to include(confidential_issue.to_reference)
          expect(json_response['description_html']).not_to include('A vulnerability')
        end
      end

      context 'when release has link asset' do
        let!(:link) do
          create(:release_link,
                 release: release,
                 name: 'release-18.04.dmg',
                 url: url)
        end

        let(:url) { 'https://my-external-hosting.example.com/scrambled-url/app.zip' }

        it 'contains link information as assets' do
          get api("/projects/#{project.id}/releases/v0.1", maintainer)

          expect(json_response['assets']['links'].count).to eq(1)
          expect(json_response['assets']['links'].first['id']).to eq(link.id)
          expect(json_response['assets']['links'].first['name'])
            .to eq('release-18.04.dmg')
          expect(json_response['assets']['links'].first['url'])
            .to eq('https://my-external-hosting.example.com/scrambled-url/app.zip')
          expect(json_response['assets']['links'].first['external'])
            .to be_truthy
        end

        context 'when link is internal' do
          let(:url) do
            "#{project.web_url}/-/jobs/artifacts/v11.6.0-rc4/download?" \
            "job=rspec-mysql+41%2F50"
          end

          it 'has external false' do
            get api("/projects/#{project.id}/releases/v0.1", maintainer)

            expect(json_response['assets']['links'].first['external'])
              .to be_falsy
          end
        end
      end

      context 'when user is a guest' do
        it 'responds 403 Forbidden' do
          get api("/projects/#{project.id}/releases/v0.1", guest)

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        context 'when project is public' do
          let(:project) { create(:project, :repository, :public) }

          it 'responds 200 OK' do
            get api("/projects/#{project.id}/releases/v0.1", guest)

            expect(response).to have_gitlab_http_status(:ok)
          end

          it "exposes tag and commit" do
            create(:release,
                   project: project,
                   tag: 'v0.1',
                   author: maintainer,
                   created_at: 2.days.ago)
            get api("/projects/#{project.id}/releases/v0.1", guest)

            expect(response).to match_response_schema('public_api/v4/release')
          end
        end
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

      expect(response).to match_response_schema('public_api/v4/release')
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

      context 'when create assets altogether' do
        let(:base_params) do
          {
            name: 'New release',
            tag_name: 'v0.1',
            description: 'Super nice release'
          }
        end

        context 'when create one asset' do
          let(:params) do
            base_params.merge({
              assets: {
                links: [{ name: 'beta', url: 'https://dosuken.example.com/inspection.exe' }]
              }
            })
          end

          it 'accepts the request' do
            post api("/projects/#{project.id}/releases", maintainer), params: params

            expect(response).to have_gitlab_http_status(:created)
          end

          it 'creates an asset with specified parameters' do
            post api("/projects/#{project.id}/releases", maintainer), params: params

            expect(json_response['assets']['links'].count).to eq(1)
            expect(json_response['assets']['links'].first['name']).to eq('beta')
            expect(json_response['assets']['links'].first['url'])
              .to eq('https://dosuken.example.com/inspection.exe')
          end

          it 'matches response schema' do
            post api("/projects/#{project.id}/releases", maintainer), params: params

            expect(response).to match_response_schema('public_api/v4/release')
          end
        end

        context 'when create two assets' do
          let(:params) do
            base_params.merge({
              assets: {
                links: [
                  { name: 'alpha', url: 'https://dosuken.example.com/alpha.exe' },
                  { name: 'beta', url: 'https://dosuken.example.com/beta.exe' }
                ]
              }
            })
          end

          it 'creates two assets with specified parameters' do
            post api("/projects/#{project.id}/releases", maintainer), params: params

            expect(json_response['assets']['links'].count).to eq(2)
            expect(json_response['assets']['links'].map { |h| h['name'] })
              .to match_array(%w[alpha beta])
            expect(json_response['assets']['links'].map { |h| h['url'] })
              .to match_array(%w[https://dosuken.example.com/alpha.exe
                                 https://dosuken.example.com/beta.exe])
          end

          context 'when link names are duplicates' do
            let(:params) do
              base_params.merge({
                assets: {
                  links: [
                    { name: 'alpha', url: 'https://dosuken.example.com/alpha.exe' },
                    { name: 'alpha', url: 'https://dosuken.example.com/beta.exe' }
                  ]
                }
              })
            end

            it 'recognizes as a bad request' do
              post api("/projects/#{project.id}/releases", maintainer), params: params

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
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

      expect(response).to match_response_schema('public_api/v4/release')
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

      expect(response).to match_response_schema('public_api/v4/release')
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
  end
end
