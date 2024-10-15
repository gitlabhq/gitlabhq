# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::DeployKeys, :aggregate_failures, feature_category: :continuous_delivery do
  let_it_be(:user)        { create(:user) }
  let_it_be(:maintainer)  { create(:user) }
  let_it_be(:admin)       { create(:admin) }
  let_it_be(:project)     { create(:project, creator_id: user.id) }
  let_it_be(:project2)    { create(:project, creator_id: user.id) }
  let_it_be(:project3)    { create(:project, creator_id: user.id) }
  let_it_be(:deploy_key) { create(:deploy_key, public: true) }
  let_it_be(:deploy_key_private) { create(:deploy_key, public: false) }
  let_it_be(:path) { '/deploy_keys' }
  let_it_be(:project_path) { "/projects/#{project.id}#{path}" }

  let!(:deploy_keys_project) do
    create(:deploy_keys_project, project: project, deploy_key: deploy_key)
  end

  describe 'GET /deploy_keys' do
    it_behaves_like 'GET request permissions for admin mode'

    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api(path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated as admin' do
      let_it_be(:pat) { create(:personal_access_token, :admin_mode, user: admin) }

      def make_api_request(params = {})
        get api(path, personal_access_token: pat), params: params
      end

      it 'returns all deploy keys' do
        make_api_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('public_api/v4/deploy_keys')
        expect(json_response).to be_an Array

        expect(json_response[0]['id']).to eq(deploy_key.id)
        expect(json_response[1]['id']).to eq(deploy_key_private.id)
      end

      it 'avoids N+1 database queries', :use_sql_query_cache, :request_store do
        create(:deploy_keys_project, :write_access, project: project2, deploy_key: deploy_key)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { make_api_request }

        deploy_key2 = create(:deploy_key, public: true)
        create(:deploy_keys_project, :write_access, project: project3, deploy_key: deploy_key2)

        expect { make_api_request }.not_to exceed_all_query_limit(control)
      end

      it 'avoids N+1 database queries', :use_sql_query_cache, :request_store do
        create(:deploy_keys_project, :readonly_access, project: project2, deploy_key: deploy_key)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { make_api_request }

        deploy_key2 = create(:deploy_key, public: true)
        create(:deploy_keys_project, :readonly_access, project: project3, deploy_key: deploy_key2)

        expect { make_api_request }.not_to exceed_all_query_limit(control)
      end

      context 'when `public` parameter is `true`' do
        it 'only returns public deploy keys' do
          make_api_request({ public: true })

          expect(json_response.length).to eq(1)
          expect(json_response.first['id']).to eq(deploy_key.id)
        end
      end

      context 'projects_with_write_access' do
        let!(:deploy_keys_project2) { create(:deploy_keys_project, :write_access, project: project2, deploy_key: deploy_key) }
        let!(:deploy_keys_project3) { create(:deploy_keys_project, :write_access, project: project3, deploy_key: deploy_key) }

        it 'returns projects with write access' do
          make_api_request

          response_projects_with_write_access = json_response.first['projects_with_write_access']

          expect(response_projects_with_write_access[0]['id']).to eq(project2.id)
          expect(response_projects_with_write_access[1]['id']).to eq(project3.id)
        end
      end

      context 'projects_with_readonly_access' do
        let!(:deploy_keys_project2) { create(:deploy_keys_project, :readonly_access, project: project2, deploy_key: deploy_key) }
        let!(:deploy_keys_project3) { create(:deploy_keys_project, :readonly_access, project: project3, deploy_key: deploy_key) }

        it 'returns projects with readonly access' do
          make_api_request

          response_projects_with_readonly_access = json_response.first['projects_with_readonly_access']

          expect(response_projects_with_readonly_access[0]['id']).to eq(project.id)
          expect(response_projects_with_readonly_access[1]['id']).to eq(project2.id)
          expect(response_projects_with_readonly_access[2]['id']).to eq(project3.id)
        end
      end
    end
  end

  describe 'POST /deploy_keys' do
    let_it_be(:path) { '/deploy_keys' }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { attributes_for :another_key }
      let(:failed_status_code) { :forbidden }
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        post api(path), params: attributes_for(:another_key)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated as admin' do
      let_it_be(:pat) { create(:personal_access_token, :admin_mode, user: admin) }

      it 'creates a new deploy key' do
        expect do
          post api(path, personal_access_token: pat), params: attributes_for(:another_key)
        end.to change { DeployKey.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
      end

      it 'does not create an invalid ssh key' do
        post api(path, personal_access_token: pat), params: { title: 'invalid key' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('key is missing')
      end

      it 'does not create a key without title' do
        post api(path, personal_access_token: pat), params: { key: 'some key' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('title is missing')
      end

      it 'returns Bad Request when deploy key is duplicated' do
        post api(path, personal_access_token: pat), params: { key: deploy_key.key, title: deploy_key.title }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['fingerprint_sha256']).to eq(['has already been taken'])
      end

      it 'accepts optional expires_at parameter' do
        expires_at = 2.days.since
        attrs = attributes_for(:another_key).merge(expires_at: expires_at.iso8601)
        post api(path, personal_access_token: pat), params: attrs

        expect(response).to have_gitlab_http_status(:created)
        expect(Time.parse(json_response['expires_at'])).to be_like_time(expires_at)
      end
    end
  end

  describe 'GET /projects/:id/deploy_keys' do
    let(:deploy_key) { create(:deploy_key, public: true, user: admin) }

    it_behaves_like 'GET request permissions for admin mode' do
      let(:path) { project_path }
      let(:failed_status_code) { :not_found }
    end

    def perform_request
      get api(project_path, admin, admin_mode: true)
    end

    it 'returns array of ssh keys' do
      perform_request

      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(deploy_key.title)
      expect(json_response.first).not_to have_key(:projects_with_write_access)
      expect(json_response.first).not_to have_key(:projects_with_readonly_access)
    end

    it 'returns multiple deploy keys without N + 1' do
      perform_request

      control = ActiveRecord::QueryRecorder.new { perform_request }

      create(:deploy_key, public: true, projects: [project], user: maintainer)

      expect { perform_request }.not_to exceed_query_limit(control)
    end
  end

  describe 'GET /projects/:id/deploy_keys/:key_id' do
    let_it_be(:path) { "#{project_path}/#{deploy_key.id}" }
    let_it_be(:unfindable_path) { "#{project_path}/404" }

    it_behaves_like 'GET request permissions for admin mode' do
      let(:failed_status_code) { :not_found }
    end

    it 'returns a single key' do
      get api(path, admin, admin_mode: true)

      expect(json_response['title']).to eq(deploy_key.title)
      expect(json_response).not_to have_key(:projects_with_write_access)
      expect(json_response).not_to have_key(:projects_with_readonly_access)
    end

    it 'returns 404 Not Found with invalid ID' do
      get api(unfindable_path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'when deploy key has expiry date' do
      let(:deploy_key) { create(:deploy_key, :expired, public: true) }
      let(:deploy_keys_project) { create(:deploy_keys_project, project: project, deploy_key: deploy_key) }

      it 'returns expiry date' do
        get api("#{project_path}/#{deploy_key.id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(Time.parse(json_response['expires_at'])).to be_like_time(deploy_key.expires_at)
      end
    end
  end

  describe 'POST /projects/:id/deploy_keys' do
    around do |example|
      freeze_time { example.run }
    end

    it_behaves_like 'POST request permissions for admin mode', :not_found do
      let(:params) { attributes_for :another_key }
      let(:path) { project_path }
      let(:failed_status_code) { :not_found }
    end

    it 'does not create an invalid ssh key' do
      post api(project_path, admin, admin_mode: true), params: { title: 'invalid key' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('key is missing')
    end

    it 'does not create a key without title' do
      post api(project_path, admin, admin_mode: true), params: { key: 'some key' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('title is missing')
    end

    it 'creates new ssh key' do
      key_attrs = attributes_for :another_key

      expect do
        post api(project_path, admin, admin_mode: true), params: key_attrs
      end.to change { project.deploy_keys.count }.by(1)

      new_key = project.deploy_keys.last
      expect(new_key.key).to eq(key_attrs[:key])
      expect(new_key.user).to eq(admin)
    end

    it 'returns an existing ssh key when attempting to add a duplicate' do
      expect do
        post api(project_path, admin, admin_mode: true), params: { key: deploy_key.key, title: deploy_key.title }
      end.not_to change { project.deploy_keys.count }

      expect(response).to have_gitlab_http_status(:created)
    end

    it 'joins an existing ssh key to a new project' do
      expect do
        post api("/projects/#{project2.id}/deploy_keys", admin, admin_mode: true), params: { key: deploy_key.key, title: deploy_key.title }
      end.to change { project2.deploy_keys.count }.by(1)

      expect(response).to have_gitlab_http_status(:created)
    end

    it 'accepts can_push parameter' do
      key_attrs = attributes_for(:another_key).merge(can_push: true)

      post api(project_path, admin, admin_mode: true), params: key_attrs

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['can_push']).to eq(true)
    end

    it 'accepts expires_at parameter' do
      expires_at = 2.days.since
      key_attrs = attributes_for(:another_key).merge(expires_at: expires_at.iso8601)

      post api(project_path, admin, admin_mode: true), params: key_attrs

      expect(response).to have_gitlab_http_status(:created)
      expect(Time.parse(json_response['expires_at'])).to be_like_time(expires_at)
    end
  end

  describe 'PUT /projects/:id/deploy_keys/:key_id' do
    let(:path) { "#{project_path}/#{deploy_key.id}" }
    let(:extra_params) { {} }
    let(:admin_mode) { false }

    it_behaves_like 'PUT request permissions for admin mode' do
      let(:params) { { title: 'new title', can_push: true } }
      let(:failed_status_code) { :not_found }
    end

    subject do
      put api(path, api_user, admin_mode: admin_mode), params: extra_params
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
      let(:admin_mode) { true }

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

        context 'with admin mode on' do
          let(:admin_mode) { true }

          it 'updates the title of the deploy key' do
            expect { subject }.to change { deploy_key.reload.title }.to 'new title'
            expect(response).to have_gitlab_http_status(:ok)
          end
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

      context 'private deploy key attached to one project' do
        let_it_be(:deploy_key) { create(:deploy_key, public: false) }
        let_it_be(:deploy_keys_project) do
          create(:deploy_keys_project, project: project, deploy_key: deploy_key)
        end

        let_it_be(:extra_params) { { title: 'new title', can_push: true } }

        it 'updates the title of the deploy key' do
          expect { subject }.to change { deploy_key.reload.title }.to('new title')
          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'updates can_push of deploy_keys_project' do
          expect { subject }.to change { deploy_keys_project.reload.can_push }.from(false).to(true)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'private deploy key attached to multiple projects' do
        let_it_be(:deploy_key) { create(:deploy_key, public: false) }
        let_it_be(:another_project) { create(:project, title: 'hello world') }
        let_it_be(:extra_params) { { title: 'new title', can_push: true } }

        let_it_be(:deploy_keys_project) do
          create(:deploy_keys_project, project: project, deploy_key: deploy_key)
        end

        before do
          create(:deploy_keys_project, project: another_project, deploy_key: deploy_key)

          another_project.add_maintainer(maintainer)
        end

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

    let(:path) { "#{project_path}/#{deploy_key.id}" }

    it_behaves_like 'DELETE request permissions for admin mode' do
      let(:failed_status_code) { :not_found }
    end

    it 'removes existing key from project' do
      expect do
        delete api(path, admin, admin_mode: true)
      end.to change { project.deploy_keys.count }.by(-1)
    end

    context 'when the deploy key is public' do
      it 'does not delete the deploy key' do
        expect do
          delete api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:no_content)
        end.not_to change { DeployKey.count }
      end
    end

    context 'when the deploy key is not public' do
      let!(:deploy_key) { create(:deploy_key, public: false) }

      context 'when the deploy key is only used by this project' do
        it 'deletes the deploy key' do
          expect do
            delete api(path, admin, admin_mode: true)

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
            delete api(path, admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:no_content)
          end.not_to change { DeployKey.count }
        end
      end
    end

    it 'returns 404 Not Found with invalid ID' do
      delete api("#{project_path}/404", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it_behaves_like '412 response' do
      let(:request) { api("#{project_path}/#{deploy_key.id}", admin, admin_mode: true) }
    end
  end

  describe 'POST /projects/:id/deploy_keys/:key_id/enable' do
    let_it_be(:project2) { create(:project) }
    let_it_be(:path) { "/projects/#{project2.id}/deploy_keys/#{deploy_key.id}/enable" }
    let_it_be(:params) { {} }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:failed_status_code) { :not_found }
    end

    context 'when the user can admin the project' do
      it 'enables the key' do
        expect do
          post api(path, admin, admin_mode: true)
        end.to change { project2.deploy_keys.count }.from(0).to(1)

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
