require 'spec_helper'

describe API::DeployKeys do
  let(:user)        { create(:user) }
  let(:admin)       { create(:admin) }
  let(:project)     { create(:project, creator_id: user.id) }
  let(:project2)    { create(:project, creator_id: user.id) }
  let(:deploy_key)  { create(:deploy_key, public: true) }

  let!(:deploy_keys_project) do
    create(:deploy_keys_project, project: project, deploy_key: deploy_key)
  end

  describe 'GET /deploy_keys' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api('/deploy_keys')

        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated as non-admin user' do
      it 'returns a 403 error' do
        get api('/deploy_keys', user)

        expect(response.status).to eq(403)
      end
    end

    context 'when authenticated as admin' do
      it 'returns all deploy keys' do
        get api('/deploy_keys', admin)

        expect(response.status).to eq(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['id']).to eq(deploy_keys_project.deploy_key.id)
      end
    end
  end

  describe 'GET /projects/:id/deploy_keys' do
    before do
      deploy_key
    end

    it 'returns array of ssh keys' do
      get api("/projects/#{project.id}/deploy_keys", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(deploy_key.title)
    end
  end

  describe 'GET /projects/:id/deploy_keys/:key_id' do
    it 'returns a single key' do
      get api("/projects/#{project.id}/deploy_keys/#{deploy_key.id}", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['title']).to eq(deploy_key.title)
    end

    it 'returns 404 Not Found with invalid ID' do
      get api("/projects/#{project.id}/deploy_keys/404", admin)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'POST /projects/:id/deploy_keys' do
    it 'does not create an invalid ssh key' do
      post api("/projects/#{project.id}/deploy_keys", admin), { title: 'invalid key' }

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('key is missing')
    end

    it 'does not create a key without title' do
      post api("/projects/#{project.id}/deploy_keys", admin), key: 'some key'

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('title is missing')
    end

    it 'creates new ssh key' do
      key_attrs = attributes_for :another_key

      expect do
        post api("/projects/#{project.id}/deploy_keys", admin), key_attrs
      end.to change { project.deploy_keys.count }.by(1)

      new_key = project.deploy_keys.last
      expect(new_key.key).to eq(key_attrs[:key])
      expect(new_key.user).to eq(admin)
    end

    it 'returns an existing ssh key when attempting to add a duplicate' do
      expect do
        post api("/projects/#{project.id}/deploy_keys", admin), { key: deploy_key.key, title: deploy_key.title }
      end.not_to change { project.deploy_keys.count }

      expect(response).to have_gitlab_http_status(201)
    end

    it 'joins an existing ssh key to a new project' do
      expect do
        post api("/projects/#{project2.id}/deploy_keys", admin), { key: deploy_key.key, title: deploy_key.title }
      end.to change { project2.deploy_keys.count }.by(1)

      expect(response).to have_gitlab_http_status(201)
    end

    it 'accepts can_push parameter' do
      key_attrs = attributes_for(:another_key).merge(can_push: true)

      post api("/projects/#{project.id}/deploy_keys", admin), key_attrs

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['can_push']).to eq(true)
    end
  end

  describe 'PUT /projects/:id/deploy_keys/:key_id' do
    let(:private_deploy_key) { create(:another_deploy_key, public: false) }
    let(:project_private_deploy_key) do
      create(:deploy_keys_project, project: project, deploy_key: private_deploy_key)
    end

    it 'updates a public deploy key as admin' do
      expect do
        put api("/projects/#{project.id}/deploy_keys/#{deploy_key.id}", admin), { title: 'new title' }
      end.not_to change(deploy_key, :title)

      expect(response).to have_gitlab_http_status(200)
    end

    it 'does not update a public deploy key as non admin' do
      expect do
        put api("/projects/#{project.id}/deploy_keys/#{deploy_key.id}", user), { title: 'new title' }
      end.not_to change(deploy_key, :title)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'does not update a private key with invalid title' do
      project_private_deploy_key

      expect do
        put api("/projects/#{project.id}/deploy_keys/#{private_deploy_key.id}", admin), { title: '' }
      end.not_to change(deploy_key, :title)

      expect(response).to have_gitlab_http_status(400)
    end

    it 'updates a private ssh key with correct attributes' do
      project_private_deploy_key

      put api("/projects/#{project.id}/deploy_keys/#{private_deploy_key.id}", admin), { title: 'new title', can_push: true }

      expect(json_response['id']).to eq(private_deploy_key.id)
      expect(json_response['title']).to eq('new title')
      expect(json_response['can_push']).to eq(true)
    end
  end

  describe 'DELETE /projects/:id/deploy_keys/:key_id' do
    before do
      deploy_key
    end

    it 'deletes existing key' do
      expect do
        delete api("/projects/#{project.id}/deploy_keys/#{deploy_key.id}", admin)

        expect(response).to have_gitlab_http_status(204)
      end.to change { project.deploy_keys.count }.by(-1)
    end

    it 'returns 404 Not Found with invalid ID' do
      delete api("/projects/#{project.id}/deploy_keys/404", admin)

      expect(response).to have_gitlab_http_status(404)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/projects/#{project.id}/deploy_keys/#{deploy_key.id}", admin) }
    end
  end

  describe 'POST /projects/:id/deploy_keys/:key_id/enable' do
    let(:project2) { create(:project) }

    context 'when the user can admin the project' do
      it 'enables the key' do
        expect do
          post api("/projects/#{project2.id}/deploy_keys/#{deploy_key.id}/enable", admin)
        end.to change { project2.deploy_keys.count }.from(0).to(1)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['id']).to eq(deploy_key.id)
      end
    end

    context 'when authenticated as non-admin user' do
      it 'returns a 404 error' do
        post api("/projects/#{project2.id}/deploy_keys/#{deploy_key.id}/enable", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
