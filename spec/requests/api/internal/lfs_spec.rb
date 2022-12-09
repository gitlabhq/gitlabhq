# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Lfs, feature_category: :source_code_management do
  include GitlabShellHelpers
  include APIInternalBaseHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:lfs_object) { create(:lfs_object, :with_file) }
  let_it_be(:lfs_objects_project) { create(:lfs_objects_project, project: project, lfs_object: lfs_object) }
  let_it_be(:gl_repository) { "project-#{project.id}" }
  let_it_be(:filename) { lfs_object.file.path }

  describe 'GET /internal/lfs' do
    let(:valid_params) do
      { oid: lfs_object.oid, gl_repository: gl_repository }
    end

    context 'with invalid auth' do
      it 'returns 401' do
        get api("/internal/lfs"),
          params: valid_params,
          headers: gitlab_shell_internal_api_request_header(issuer: 'gitlab-workhorse')
      end
    end

    context 'with valid auth' do
      context 'LFS in local storage' do
        it 'sends the file' do
          get api("/internal/lfs"), params: valid_params, headers: gitlab_shell_internal_api_request_header

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Content-Type']).to eq('application/octet-stream')
          expect(response.headers['Content-Length'].to_i).to eq(File.stat(filename).size)
          expect(response.body).to eq(File.open(filename, 'rb', &:read))
        end

        # https://www.rubydoc.info/github/rack/rack/master/Rack/Sendfile
        it 'delegates sending to Web server' do
          get api("/internal/lfs"),
            params: valid_params,
            env: { 'HTTP_X_SENDFILE_TYPE' => 'X-Sendfile' },
            headers: gitlab_shell_internal_api_request_header

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Content-Type']).to eq('application/octet-stream')
          expect(response.headers['Content-Length'].to_i).to eq(0)
          expect(response.headers['X-Sendfile']).to be_present
          expect(response.body).to eq("")
        end

        it 'retuns 404 for unknown file' do
          params = valid_params.merge(oid: SecureRandom.hex)

          get api("/internal/lfs"), params: params, headers: gitlab_shell_internal_api_request_header

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 404 if LFS object does not belong to project' do
          other_lfs = create(:lfs_object, :with_file)
          params = valid_params.merge(oid: other_lfs.oid)

          get api("/internal/lfs"), params: params, headers: gitlab_shell_internal_api_request_header

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'LFS in object storage' do
        let!(:lfs_object2) { create(:lfs_object, :with_file) }
        let!(:lfs_objects_project2) { create(:lfs_objects_project, project: project, lfs_object: lfs_object2) }
        let(:valid_params) do
          { oid: lfs_object2.oid, gl_repository: gl_repository }
        end

        before do
          stub_lfs_object_storage(enabled: true)
          lfs_object2.file.migrate!(LfsObjectUploader::Store::REMOTE)
        end

        it 'notifies Workhorse to send the file' do
          get api("/internal/lfs"), params: valid_params, headers: gitlab_shell_internal_api_request_header

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("send-url:")
          expect(response.headers['Content-Type']).to eq('application/octet-stream')
          expect(response.headers['Content-Length'].to_i).to eq(0)
          expect(response.body).to eq("")
        end
      end
    end
  end
end
