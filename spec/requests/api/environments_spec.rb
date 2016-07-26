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
      it 'should return project environments' do
        get api("/projects/#{project.id}/environments", user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
        expect(json_response.first['name']).to eq(environment.name)
        expect(json_response.first['external_url']).to eq(environment.external_url)
      end
    end

    context 'as non member' do
      it 'should return a 404 status code' do
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

      it 'should return 400 if environment already exists' do
        post api("/projects/#{project.id}/environments", user), name: environment.name

        expect(response).to have_http_status(400)
      end
    end

    context 'a non member' do
      it 'rejects the request' do
        post api("/projects/#{project.id}/environments", non_member)

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'DELETE /projects/:id/environments/:environment_id' do
    context 'as a master' do
      it 'should return 200 for an existing environment' do
        delete api("/projects/#{project.id}/environments/#{environment.id}", user)

        expect(response).to have_http_status(200)
      end

      it 'should return 404 for non existing id' do
        delete api("/projects/#{project.id}/environments/12345", user)

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Not found')
      end
    end
  end

  describe 'PUT /projects/:id/environments/:environment_id' do
    it 'should return 200 if name and external_url are changed' do
      put api("/projects/#{project.id}/environments/#{environment.id}", user),
          name: 'Mepmep', external_url: 'https://mepmep.whatever.ninja'

      expect(response).to have_http_status(200)
      expect(json_response['name']).to eq('Mepmep')
      expect(json_response['external_url']).to eq('https://mepmep.whatever.ninja')
    end

    it 'should return 404 if the environment does not exist' do
      put api("/projects/#{project.id}/environments/12345", user)

      expect(response).to have_http_status(404)
    end
  end
end
