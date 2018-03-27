require 'spec_helper'

describe API::V3::Environments do
  let(:user)          { create(:user) }
  let(:non_member)    { create(:user) }
  let(:project)       { create(:project, :private, namespace: user.namespace) }
  let!(:environment)  { create(:environment, project: project) }

  before do
    project.add_master(user)
  end

  shared_examples 'a paginated resources' do
    before do
      # Fires the request
      request
    end

    it 'has pagination headers' do
      expect(response.headers).to include('X-Total')
      expect(response.headers).to include('X-Total-Pages')
      expect(response.headers).to include('X-Per-Page')
      expect(response.headers).to include('X-Page')
      expect(response.headers).to include('X-Next-Page')
      expect(response.headers).to include('X-Prev-Page')
      expect(response.headers).to include('Link')
    end
  end

  describe 'GET /projects/:id/environments' do
    context 'as member of the project' do
      it_behaves_like 'a paginated resources' do
        let(:request) { get v3_api("/projects/#{project.id}/environments", user) }
      end

      it 'returns project environments' do
        get v3_api("/projects/#{project.id}/environments", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
        expect(json_response.first['name']).to eq(environment.name)
        expect(json_response.first['external_url']).to eq(environment.external_url)
        expect(json_response.first['project']['id']).to eq(project.id)
        expect(json_response.first['project']['visibility_level']).to be_present
      end
    end

    context 'as non member' do
      it 'returns a 404 status code' do
        get v3_api("/projects/#{project.id}/environments", non_member)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'POST /projects/:id/environments' do
    context 'as a member' do
      it 'creates a environment with valid params' do
        post v3_api("/projects/#{project.id}/environments", user), name: "mepmep"

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq('mepmep')
        expect(json_response['slug']).to eq('mepmep')
        expect(json_response['external']).to be nil
      end

      it 'requires name to be passed' do
        post v3_api("/projects/#{project.id}/environments", user), external_url: 'test.gitlab.com'

        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns a 400 if environment already exists' do
        post v3_api("/projects/#{project.id}/environments", user), name: environment.name

        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns a 400 if slug is specified' do
        post v3_api("/projects/#{project.id}/environments", user), name: "foo", slug: "foo"

        expect(response).to have_gitlab_http_status(400)
        expect(json_response["error"]).to eq("slug is automatically generated and cannot be changed")
      end
    end

    context 'a non member' do
      it 'rejects the request' do
        post v3_api("/projects/#{project.id}/environments", non_member), name: 'gitlab.com'

        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns a 400 when the required params are missing' do
        post v3_api("/projects/12345/environments", non_member), external_url: 'http://env.git.com'
      end
    end
  end

  describe 'PUT /projects/:id/environments/:environment_id' do
    it 'returns a 200 if name and external_url are changed' do
      url = 'https://mepmep.whatever.ninja'
      put v3_api("/projects/#{project.id}/environments/#{environment.id}", user),
          name: 'Mepmep', external_url: url

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['name']).to eq('Mepmep')
      expect(json_response['external_url']).to eq(url)
    end

    it "won't allow slug to be changed" do
      slug = environment.slug
      api_url = v3_api("/projects/#{project.id}/environments/#{environment.id}", user)
      put api_url, slug: slug + "-foo"

      expect(response).to have_gitlab_http_status(400)
      expect(json_response["error"]).to eq("slug is automatically generated and cannot be changed")
    end

    it "won't update the external_url if only the name is passed" do
      url = environment.external_url
      put v3_api("/projects/#{project.id}/environments/#{environment.id}", user),
          name: 'Mepmep'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['name']).to eq('Mepmep')
      expect(json_response['external_url']).to eq(url)
    end

    it 'returns a 404 if the environment does not exist' do
      put v3_api("/projects/#{project.id}/environments/12345", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'DELETE /projects/:id/environments/:environment_id' do
    context 'as a master' do
      it 'returns a 200 for an existing environment' do
        delete v3_api("/projects/#{project.id}/environments/#{environment.id}", user)

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns a 404 for non existing id' do
        delete v3_api("/projects/#{project.id}/environments/12345", user)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Not found')
      end
    end

    context 'a non member' do
      it 'rejects the request' do
        delete v3_api("/projects/#{project.id}/environments/#{environment.id}", non_member)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
