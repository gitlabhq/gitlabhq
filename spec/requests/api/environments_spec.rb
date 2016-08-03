require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:user)          { create(:user) }
  let(:non_member)    { create(:user) }
  let(:project)       { create(:project, :private, namespace: user.namespace) }
  let!(:environment)  { create(:environment, project: project) }

  before do
    project.team << [user, :master]
  end

  describe 'GET /projects/:id/environments' do
    context 'as member of the project' do
      it_behaves_like 'a paginated resources' do
        let(:request) { get api("/projects/#{project.id}/environments", user) }
      end

      it 'returns project environments' do
        get api("/projects/#{project.id}/environments", user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
        expect(json_response.first['name']).to eq(environment.name)
        expect(json_response.first['external_url']).to eq(environment.external_url)
      end
    end

    context 'as non member' do
      it 'returns a 404 status code' do
        get api("/projects/#{project.id}/environments", non_member)

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'POST /projects/:id/environments' do
    context 'as a member' do
      it 'creates a environment with valid params' do
        post api("/projects/#{project.id}/environments", user), name: "mepmep"

        expect(response).to have_http_status(201)
        expect(json_response['name']).to eq('mepmep')
        expect(json_response['external']).to be nil
      end

      it 'requires name to be passed' do
        post api("/projects/#{project.id}/environments", user), external_url: 'test.gitlab.com'

        expect(response).to have_http_status(400)
      end

      it 'returns a 400 if environment already exists' do
        post api("/projects/#{project.id}/environments", user), name: environment.name

        expect(response).to have_http_status(400)
      end
    end

    context 'a non member' do
      it 'rejects the request' do
        post api("/projects/#{project.id}/environments", non_member), name: 'gitlab.com'

        expect(response).to have_http_status(404)
      end

      it 'returns a 400 when the required params are missing' do
        post api("/projects/12345/environments", non_member), external_url: 'http://env.git.com'
      end
    end
  end

  describe 'PUT /projects/:id/environments/:environment_id' do
    it 'returns a 200 if name and external_url are changed' do
      url = 'https://mepmep.whatever.ninja'
      put api("/projects/#{project.id}/environments/#{environment.id}", user),
          name: 'Mepmep', external_url: url

      expect(response).to have_http_status(200)
      expect(json_response['name']).to eq('Mepmep')
      expect(json_response['external_url']).to eq(url)
    end

    it "won't update the external_url if only the name is passed" do
      url = environment.external_url
      put api("/projects/#{project.id}/environments/#{environment.id}", user),
          name: 'Mepmep'

      expect(response).to have_http_status(200)
      expect(json_response['name']).to eq('Mepmep')
      expect(json_response['external_url']).to eq(url)
    end

    it 'returns a 404 if the environment does not exist' do
      put api("/projects/#{project.id}/environments/12345", user)

      expect(response).to have_http_status(404)
    end
  end

  describe 'DELETE /projects/:id/environments/:environment_id' do
    context 'as a master' do
      it 'returns a 200 for an existing environment' do
        delete api("/projects/#{project.id}/environments/#{environment.id}", user)

        expect(response).to have_http_status(200)
      end

      it 'returns a 404 for non existing id' do
        delete api("/projects/#{project.id}/environments/12345", user)

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Not found')
      end
    end

    context 'a non member' do
      it 'rejects the request' do
        delete api("/projects/#{project.id}/environments/#{environment.id}", non_member)

        expect(response).to have_http_status(404)
      end
    end
  end
end
