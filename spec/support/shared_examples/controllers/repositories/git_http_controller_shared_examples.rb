# frozen_string_literal: true

RSpec.shared_examples Repositories::GitHttpController do
  include GitHttpHelpers

  let(:repository_path) { "#{container.full_path}.git" }
  let(:params) { { repository_path: repository_path } }

  describe 'HEAD #info_refs' do
    it 'returns 403' do
      head :info_refs, params: params

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'GET #info_refs' do
    let(:params) { super().merge(service: 'git-upload-pack') }

    it 'returns 401 for unauthenticated requests to public repositories when http protocol is disabled' do
      stub_application_setting(enabled_git_access_protocol: 'ssh')
      allow(controller).to receive(:basic_auth_provided?).and_call_original

      expect(controller).to receive(:http_download_allowed?).and_call_original

      get :info_refs, params: params

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'calls the right access checker class with the right object' do
      allow(controller).to receive(:verify_workhorse_api!).and_return(true)

      access_double = double
      options = {
        authentication_abilities: [:download_code],
        repository_path: repository_path,
        redirected_path: nil,
        auth_result_type: :none
      }

      expect(access_checker_class).to receive(:new)
        .with(nil, container, 'http', hash_including(options))
        .and_return(access_double)

      allow(access_double).to receive(:check).and_return(false)

      get :info_refs, params: params
    end

    context 'with authorized user' do
      before do
        password = user.try(:password) || user.try(:token)
        request.headers.merge! auth_env(user.username, password, nil)
      end

      it 'returns 200' do
        get :info_refs, params: params

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'updates the user activity' do
        activity_project = container.is_a?(PersonalSnippet) ? nil : project

        activity_service = instance_double(Users::ActivityService)

        args = { author: user, project: activity_project, namespace: activity_project&.namespace }
        expect(Users::ActivityService).to receive(:new).with(args).and_return(activity_service)

        expect(activity_service).to receive(:execute)

        get :info_refs, params: params
      end

      include_context 'parsed logs' do
        it 'adds user info to the logs' do
          get :info_refs, params: params

          user_log_data = { 'username' => user.username, 'user_id' => user.id }
          user_log_data['meta.user'] = user.username if user.is_a?(User)

          expect(log_data).to include(user_log_data)
        end
      end
    end
  end

  describe 'POST #git_upload_pack' do
    it 'returns 200' do
      allow(controller).to receive(:verify_workhorse_api!).and_return(true)

      post :git_upload_pack, params: params

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when JWT token is not provided' do
      it 'returns 403' do
        post :git_upload_pack, params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
