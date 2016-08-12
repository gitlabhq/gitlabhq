require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:user)        { create(:user) }
  let(:admin)       { create(:admin) }
  let(:project)     { create(:project, creator_id: user.id) }
  let(:deploy_key)  { create(:deploy_key, public: true) }

  let!(:deploy_keys_project) do
    create(:deploy_keys_project, project: project, deploy_key: deploy_key)
  end

  describe 'GET /deploy_keys' do
    context 'when unauthenticated' do
      it 'should return authentication error' do
        get api('/deploy_keys')

        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated as non-admin user' do
      it 'should return a 403 error' do
        get api('/deploy_keys', user)

        expect(response.status).to eq(403)
      end
    end

    context 'when authenticated as admin' do
      it 'should return all deploy keys' do
        get api('/deploy_keys', admin)

        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.first['id']).to eq(deploy_keys_project.deploy_key.id)
      end
    end
  end

  describe 'GET /projects/:id/deploy_keys' do
    before { deploy_key }

    it 'should return array of ssh keys' do
      get api("/projects/#{project.id}/deploy_keys", admin)

      expect(response).to have_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(deploy_key.title)
    end
  end

  describe 'GET /projects/:id/deploy_keys/:key_id' do
    it 'should return a single key' do
      get api("/projects/#{project.id}/deploy_keys/#{deploy_key.id}", admin)

      expect(response).to have_http_status(200)
      expect(json_response['title']).to eq(deploy_key.title)
    end

    it 'should return 404 Not Found with invalid ID' do
      get api("/projects/#{project.id}/deploy_keys/404", admin)

      expect(response).to have_http_status(404)
    end
  end

  describe 'POST /projects/:id/deploy_keys' do
    it 'should not create an invalid ssh key' do
      post api("/projects/#{project.id}/deploy_keys", admin), { title: 'invalid key' }

      expect(response).to have_http_status(400)
      expect(json_response['message']['key']).to eq([
        'can\'t be blank',
        'is too short (minimum is 0 characters)',
        'is invalid'
      ])
    end

    it 'should not create a key without title' do
      post api("/projects/#{project.id}/deploy_keys", admin), key: 'some key'

      expect(response).to have_http_status(400)
      expect(json_response['message']['title']).to eq([
        'can\'t be blank',
        'is too short (minimum is 0 characters)'
      ])
    end

    it 'should create new ssh key' do
      key_attrs = attributes_for :another_key

      expect do
        post api("/projects/#{project.id}/deploy_keys", admin), key_attrs
      end.to change{ project.deploy_keys.count }.by(1)
    end
  end

  describe 'DELETE /projects/:id/deploy_keys/:key_id' do
    before { deploy_key }

    it 'should delete existing key' do
      expect do
        delete api("/projects/#{project.id}/deploy_keys/#{deploy_key.id}", admin)
      end.to change{ project.deploy_keys.count }.by(-1)
    end

    it 'should return 404 Not Found with invalid ID' do
      delete api("/projects/#{project.id}/deploy_keys/404", admin)

      expect(response).to have_http_status(404)
    end
  end

  describe 'POST /projects/:id/deploy_keys/:key_id/enable' do
    let(:project2) { create(:empty_project) }

    context 'when the user can admin the project' do
      it 'enables the key' do
        expect do
          post api("/projects/#{project2.id}/deploy_keys/#{deploy_key.id}/enable", admin)
        end.to change { project2.deploy_keys.count }.from(0).to(1)

        expect(response).to have_http_status(201)
        expect(json_response['id']).to eq(deploy_key.id)
      end
    end

    context 'when authenticated as non-admin user' do
      it 'should return a 404 error' do
        post api("/projects/#{project2.id}/deploy_keys/#{deploy_key.id}/enable", user)

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'DELETE /projects/:id/deploy_keys/:key_id/disable' do
    context 'when the user can admin the project' do
      it 'disables the key' do
        expect do
          delete api("/projects/#{project.id}/deploy_keys/#{deploy_key.id}/disable", admin)
        end.to change { project.deploy_keys.count }.from(1).to(0)

        expect(response).to have_http_status(200)
        expect(json_response['id']).to eq(deploy_key.id)
      end
    end

    context 'when authenticated as non-admin user' do
      it 'should return a 404 error' do
        delete api("/projects/#{project.id}/deploy_keys/#{deploy_key.id}/disable", user)

        expect(response).to have_http_status(404)
      end
    end
  end
end
