require 'spec_helper'

describe API::V3::DeployKeys do
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
      it 'should return authentication error' do
        get v3_api('/deploy_keys')

        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated as non-admin user' do
      it 'should return a 403 error' do
        get v3_api('/deploy_keys', user)

        expect(response.status).to eq(403)
      end
    end

    context 'when authenticated as admin' do
      it 'should return all deploy keys' do
        get v3_api('/deploy_keys', admin)

        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.first['id']).to eq(deploy_keys_project.deploy_key.id)
      end
    end
  end

  %w(deploy_keys keys).each do |path|
    describe "GET /projects/:id/#{path}" do
      before { deploy_key }

      it 'should return array of ssh keys' do
        get v3_api("/projects/#{project.id}/#{path}", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['title']).to eq(deploy_key.title)
      end
    end

    describe "GET /projects/:id/#{path}/:key_id" do
      it 'should return a single key' do
        get v3_api("/projects/#{project.id}/#{path}/#{deploy_key.id}", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq(deploy_key.title)
      end

      it 'should return 404 Not Found with invalid ID' do
        get v3_api("/projects/#{project.id}/#{path}/404", admin)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    describe "POST /projects/:id/deploy_keys" do
      it 'should not create an invalid ssh key' do
        post v3_api("/projects/#{project.id}/#{path}", admin), { title: 'invalid key' }

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['error']).to eq('key is missing')
      end

      it 'should not create a key without title' do
        post v3_api("/projects/#{project.id}/#{path}", admin), key: 'some key'

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['error']).to eq('title is missing')
      end

      it 'should create new ssh key' do
        key_attrs = attributes_for :another_key

        expect do
          post v3_api("/projects/#{project.id}/#{path}", admin), key_attrs
        end.to change { project.deploy_keys.count }.by(1)
      end

      it 'returns an existing ssh key when attempting to add a duplicate' do
        expect do
          post v3_api("/projects/#{project.id}/#{path}", admin), { key: deploy_key.key, title: deploy_key.title }
        end.not_to change { project.deploy_keys.count }

        expect(response).to have_gitlab_http_status(201)
      end

      it 'joins an existing ssh key to a new project' do
        expect do
          post v3_api("/projects/#{project2.id}/#{path}", admin), { key: deploy_key.key, title: deploy_key.title }
        end.to change { project2.deploy_keys.count }.by(1)

        expect(response).to have_gitlab_http_status(201)
      end

      it 'accepts can_push parameter' do
        key_attrs = attributes_for(:another_key).merge(can_push: true)

        post v3_api("/projects/#{project.id}/#{path}", admin), key_attrs

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['can_push']).to eq(true)
      end
    end

    describe "DELETE /projects/:id/#{path}/:key_id" do
      before { deploy_key }

      it 'should delete existing key' do
        expect do
          delete v3_api("/projects/#{project.id}/#{path}/#{deploy_key.id}", admin)
        end.to change { project.deploy_keys.count }.by(-1)
      end

      it 'should return 404 Not Found with invalid ID' do
        delete v3_api("/projects/#{project.id}/#{path}/404", admin)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    describe "POST /projects/:id/#{path}/:key_id/enable" do
      let(:project2) { create(:project) }

      context 'when the user can admin the project' do
        it 'enables the key' do
          expect do
            post v3_api("/projects/#{project2.id}/#{path}/#{deploy_key.id}/enable", admin)
          end.to change { project2.deploy_keys.count }.from(0).to(1)

          expect(response).to have_gitlab_http_status(201)
          expect(json_response['id']).to eq(deploy_key.id)
        end
      end

      context 'when authenticated as non-admin user' do
        it 'should return a 404 error' do
          post v3_api("/projects/#{project2.id}/#{path}/#{deploy_key.id}/enable", user)

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    describe "DELETE /projects/:id/deploy_keys/:key_id/disable" do
      context 'when the user can admin the project' do
        it 'disables the key' do
          expect do
            delete v3_api("/projects/#{project.id}/#{path}/#{deploy_key.id}/disable", admin)
          end.to change { project.deploy_keys.count }.from(1).to(0)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['id']).to eq(deploy_key.id)
        end
      end

      context 'when authenticated as non-admin user' do
        it 'should return a 404 error' do
          delete v3_api("/projects/#{project.id}/#{path}/#{deploy_key.id}/disable", user)

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end
end
