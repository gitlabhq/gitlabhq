# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::DeployKeys do
  let_it_be(:user)        { create(:user) }
  let_it_be(:maintainer)  { create(:user) }
  let_it_be(:admin)       { create(:admin) }
  let_it_be(:project)     { create(:project, creator_id: user.id) }
  let_it_be(:project2)    { create(:project, creator_id: user.id) }

  let(:deploy_key) { create(:deploy_key, public: true) }

  let!(:deploy_keys_project) do
    create(:deploy_keys_project, project: project, deploy_key: deploy_key)
  end

  describe 'GET /deploy_keys' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api('/deploy_keys')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated as non-admin user' do
      it 'returns a 403 error' do
        get api('/deploy_keys', user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      it 'returns all deploy keys' do
        get api('/deploy_keys', admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['id']).to eq(deploy_keys_project.deploy_key.id)
      end
    end
  end

  describe 'GET /projects/:id/deploy_keys' do
    let(:deploy_key) { create(:deploy_key, public: true, user: admin) }

    def perform_request
      get api("/projects/#{project.id}/deploy_keys", admin)
    end

    it 'returns array of ssh keys' do
      perform_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(deploy_key.title)
    end

    it 'returns multiple deploy keys without N + 1' do
      perform_request

      control_count = ActiveRecord::QueryRecorder.new { perform_request }.count

      create(:deploy_key, public: true, projects: [project], user: maintainer)

      expect { perform_request }.not_to exceed_query_limit(control_count)
    end
  end

  describe 'GET /projects/:id/deploy_keys/:key_id' do
    it 'returns a single key' do
      get api("/projects/#{project.id}/deploy_keys/#{deploy_key.id}", admin)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['title']).to eq(deploy_key.title)
    end

    it 'returns 404 Not Found with invalid ID' do
      get api("/projects/#{project.id}/deploy_keys/404", admin)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'POST /projects/:id/deploy_keys' do
    it 'does not create an invalid ssh key' do
      post api("/projects/#{project.id}/deploy_keys", admin), params: { title: 'invalid key' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('key is missing')
    end

    it 'does not create a key without title' do
      post api("/projects/#{project.id}/deploy_keys", admin), params: { key: 'some key' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('title is missing')
    end

    it 'creates new ssh key' do
      key_attrs = attributes_for :another_key

      expect do
        post api("/projects/#{project.id}/deploy_keys", admin), params: key_attrs
      end.to change { project.deploy_keys.count }.by(1)

      new_key = project.deploy_keys.last
      expect(new_key.key).to eq(key_attrs[:key])
      expect(new_key.user).to eq(admin)
    end

    it 'returns an existing ssh key when attempting to add a duplicate' do
      expect do
        post api("/projects/#{project.id}/deploy_keys", admin), params: { key: deploy_key.key, title: deploy_key.title }
      end.not_to change { project.deploy_keys.count }

      expect(response).to have_gitlab_http_status(:created)
    end

    it 'joins an existing ssh key to a new project' do
      expect do
        post api("/projects/#{project2.id}/deploy_keys", admin), params: { key: deploy_key.key, title: deploy_key.title }
      end.to change { project2.deploy_keys.count }.by(1)

      expect(response).to have_gitlab_http_status(:created)
    end

    it 'accepts can_push parameter' do
      key_attrs = attributes_for(:another_key).merge(can_push: true)

      post api("/projects/#{project.id}/deploy_keys", admin), params: key_attrs

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['can_push']).to eq(true)
    end
  end

  describe 'PUT /projects/:id/deploy_keys/:key_id' do
    let(:extra_params) { {} }

    subject do
      put api("/projects/#{project.id}/deploy_keys/#{deploy_key.id}", api_user), params: extra_params
    end

    context 'with non-admin' do
      let(:api_user) { user }

      it 'does not update a public deploy key' do
        expect { subject }.not_to change(deploy_key, :title)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with admin' do
      let(:api_user) { admin }

      context 'public deploy key attached to project' do
        let(:extra_params) { { title: 'new title', can_push: true } }

        it 'updates the title of the deploy key' do
          expect { subject }.to change { deploy_key.reload.title }.to 'new title'
          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'updates can_push of deploy_keys_project' do
          expect { subject }.to change { deploy_keys_project.reload.can_push }.from(false).to(true)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'private deploy key' do
        let(:deploy_key) { create(:another_deploy_key, public: false) }
        let(:deploy_keys_project) do
          create(:deploy_keys_project, project: project, deploy_key: deploy_key)
        end

        let(:extra_params) { { title: 'new title', can_push: true } }

        it 'updates the title of the deploy key' do
          expect { subject }.to change { deploy_key.reload.title }.to 'new title'
          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'updates can_push of deploy_keys_project' do
          expect { subject }.to change { deploy_keys_project.reload.can_push }.from(false).to(true)
          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'invalid title' do
          let(:extra_params) { { title: '' } }

          it 'does not update the title of the deploy key' do
            expect { subject }.not_to change { deploy_key.reload.title }
            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end
    end

    context 'with admin as project maintainer' do
      let(:api_user) { admin }

      before do
        project.add_maintainer(admin)
      end

      context 'public deploy key attached to project' do
        let(:extra_params) { { title: 'new title', can_push: true } }

        it 'updates the title of the deploy key' do
          expect { subject }.to change { deploy_key.reload.title }.to 'new title'
          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'updates can_push of deploy_keys_project' do
          expect { subject }.to change { deploy_keys_project.reload.can_push }.from(false).to(true)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'with maintainer' do
      let(:api_user) { maintainer }

      before do
        project.add_maintainer(maintainer)
      end

      context 'public deploy key attached to project' do
        let(:extra_params) { { title: 'new title', can_push: true } }

        it 'does not update the title of the deploy key' do
          expect { subject }.not_to change { deploy_key.reload.title }
          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'updates can_push of deploy_keys_project' do
          expect { subject }.to change { deploy_keys_project.reload.can_push }.from(false).to(true)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'DELETE /projects/:id/deploy_keys/:key_id' do
    before do
      deploy_key
    end

    it 'removes existing key from project' do
      expect do
        delete api("/projects/#{project.id}/deploy_keys/#{deploy_key.id}", admin)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { project.deploy_keys.count }.by(-1)
    end

    context 'when the deploy key is public' do
      it 'does not delete the deploy key' do
        expect do
          delete api("/projects/#{project.id}/deploy_keys/#{deploy_key.id}", admin)

          expect(response).to have_gitlab_http_status(:no_content)
        end.not_to change { DeployKey.count }
      end
    end

    context 'when the deploy key is not public' do
      let!(:deploy_key) { create(:deploy_key, public: false) }

      context 'when the deploy key is only used by this project' do
        it 'deletes the deploy key' do
          expect do
            delete api("/projects/#{project.id}/deploy_keys/#{deploy_key.id}", admin)

            expect(response).to have_gitlab_http_status(:no_content)
          end.to change { DeployKey.count }.by(-1)
        end
      end

      context 'when the deploy key is used by other projects' do
        before do
          create(:deploy_keys_project, project: project2, deploy_key: deploy_key)
        end

        it 'does not delete the deploy key' do
          expect do
            delete api("/projects/#{project.id}/deploy_keys/#{deploy_key.id}", admin)

            expect(response).to have_gitlab_http_status(:no_content)
          end.not_to change { DeployKey.count }
        end
      end
    end

    it 'returns 404 Not Found with invalid ID' do
      delete api("/projects/#{project.id}/deploy_keys/404", admin)

      expect(response).to have_gitlab_http_status(:not_found)
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

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['id']).to eq(deploy_key.id)
      end
    end

    context 'when authenticated as non-admin user' do
      it 'returns a 404 error' do
        post api("/projects/#{project2.id}/deploy_keys/#{deploy_key.id}/enable", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
