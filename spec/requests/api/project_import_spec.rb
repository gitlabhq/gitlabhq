# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectImport do
  include WorkhorseHelpers

  let(:export_path) { "#{Dir.tmpdir}/project_export_spec" }
  let(:user) { create(:user) }
  let(:file) { File.join('spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz') }
  let(:namespace) { create(:group) }

  let(:workhorse_token) { JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256') }
  let(:workhorse_headers) { { 'GitLab-Workhorse' => '1.0', Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => workhorse_token } }

  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    stub_uploads_object_storage(FileUploader)

    namespace.add_owner(user)
  end

  after do
    FileUtils.rm_rf(export_path, secure: true)
  end

  describe 'POST /projects/import' do
    it 'schedules an import using a namespace' do
      stub_import(namespace)

      post api('/projects/import', user), params: { path: 'test-import', file: fixture_file_upload(file), namespace: namespace.id }

      expect(response).to have_gitlab_http_status(:created)
    end

    it 'schedules an import using the namespace path' do
      stub_import(namespace)

      post api('/projects/import', user), params: { path: 'test-import', file: fixture_file_upload(file), namespace: namespace.full_path }

      expect(response).to have_gitlab_http_status(:created)
    end

    context 'when a name is explicitly set' do
      let(:expected_name) { 'test project import' }

      it 'schedules an import using a namespace and a different name' do
        stub_import(namespace)

        post api('/projects/import', user), params: { path: 'test-import', file: fixture_file_upload(file), namespace: namespace.id, name: expected_name }

        expect(response).to have_gitlab_http_status(:created)
      end

      it 'schedules an import using the namespace path and a different name' do
        stub_import(namespace)

        post api('/projects/import', user), params: { path: 'test-import', file: fixture_file_upload(file), namespace: namespace.full_path, name: expected_name }

        expect(response).to have_gitlab_http_status(:created)
      end

      it 'sets name correctly' do
        stub_import(namespace)

        post api('/projects/import', user), params: { path: 'test-import', file: fixture_file_upload(file), namespace: namespace.full_path, name: expected_name }

        project = Project.find(json_response['id'])
        expect(project.name).to eq(expected_name)
      end

      it 'sets name correctly with an overwrite' do
        stub_import(namespace)

        post api('/projects/import', user), params: { path: 'test-import', file: fixture_file_upload(file), namespace: namespace.full_path, name: 'new project name', overwrite: true }

        project = Project.find(json_response['id'])
        expect(project.name).to eq('new project name')
      end

      it 'schedules an import using the path and name explicitly set to nil' do
        stub_import(namespace)

        post api('/projects/import', user), params: { path: 'test-import', file: fixture_file_upload(file), namespace: namespace.full_path, name: nil }

        project = Project.find(json_response['id'])
        expect(project.name).to eq('test-import')
      end
    end

    it 'schedules an import at the user namespace level' do
      stub_import(user.namespace)

      post api('/projects/import', user), params: { path: 'test-import2', file: fixture_file_upload(file) }

      expect(response).to have_gitlab_http_status(:created)
    end

    it 'does not schedule an import for a namespace that does not exist' do
      expect_any_instance_of(ProjectImportState).not_to receive(:schedule)
      expect(::Projects::CreateService).not_to receive(:new)

      post api('/projects/import', user), params: { namespace: 'nonexistent', path: 'test-import2', file: fixture_file_upload(file) }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Namespace Not Found')
    end

    it 'does not schedule an import if the user has no permission to the namespace' do
      expect_any_instance_of(ProjectImportState).not_to receive(:schedule)

      post(api('/projects/import', create(:user)),
           params: {
             path: 'test-import3',
             file: fixture_file_upload(file),
             namespace: namespace.full_path
           })

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Namespace Not Found')
    end

    it 'does not schedule an import if the user uploads no valid file' do
      expect_any_instance_of(ProjectImportState).not_to receive(:schedule)

      post api('/projects/import', user), params: { path: 'test-import3', file: './random/test' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('file is invalid')
    end

    it 'stores params that can be overridden' do
      stub_import(namespace)
      override_params = { 'description' => 'Hello world' }

      post api('/projects/import', user),
           params: {
             path: 'test-import',
             file: fixture_file_upload(file),
             namespace: namespace.id,
             override_params: override_params
           }
      import_project = Project.find(json_response['id'])

      expect(import_project.import_data.data['override_params']).to eq(override_params)
    end

    it 'does not store params that are not allowed' do
      stub_import(namespace)
      override_params = { 'not_allowed' => 'Hello world' }

      post api('/projects/import', user),
           params: {
             path: 'test-import',
             file: fixture_file_upload(file),
             namespace: namespace.id,
             override_params: override_params
           }
      import_project = Project.find(json_response['id'])

      expect(import_project.import_data.data['override_params']).to be_empty
    end

    it 'correctly overrides params during the import', :sidekiq_might_not_need_inline do
      override_params = { 'description' => 'Hello world' }

      perform_enqueued_jobs do
        post api('/projects/import', user),
             params: {
               path: 'test-import',
               file: fixture_file_upload(file),
               namespace: namespace.id,
               override_params: override_params
             }
      end
      import_project = Project.find(json_response['id'])

      expect(import_project.description).to eq('Hello world')
    end

    context 'when target path already exists in namespace' do
      let(:existing_project) { create(:project, namespace: user.namespace) }

      it 'does not schedule an import' do
        expect_any_instance_of(ProjectImportState).not_to receive(:schedule)

        post api('/projects/import', user), params: { path: existing_project.path, file: fixture_file_upload(file) }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq('Name has already been taken')
      end

      context 'when param overwrite is true' do
        it 'schedules an import' do
          stub_import(user.namespace)

          post api('/projects/import', user), params: { path: existing_project.path, file: fixture_file_upload(file), overwrite: true }

          expect(response).to have_gitlab_http_status(:created)
        end
      end
    end

    context 'when request exceeds the rate limit' do
      before do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)
      end

      it 'prevents users from importing projects' do
        post api('/projects/import', user), params: { path: 'test-import', file: fixture_file_upload(file), namespace: namespace.id }

        expect(response).to have_gitlab_http_status(:too_many_requests)
        expect(json_response['message']['error']).to eq('This endpoint has been requested too many times. Try again later.')
      end
    end

    context 'with direct upload enabled' do
      subject { upload_archive(file_upload, workhorse_headers, params) }

      let(:file_name) { 'project_export.tar.gz' }

      let!(:fog_connection) do
        stub_uploads_object_storage(ImportExportUploader, direct_upload: true)
      end

      let(:tmp_object) do
        fog_connection.directories.new(key: 'uploads').files.create(
          key: "tmp/uploads/#{file_name}",
          body: fixture_file_upload(file)
        )
      end

      let(:file_upload) { fog_to_uploaded_file(tmp_object) }

      let(:params) do
        {
          path: 'test-import-project',
          namespace: namespace.id,
          'file.remote_id' => file_name,
          'file.size' => file_upload.size
        }
      end

      before do
        allow(ImportExportUploader).to receive(:workhorse_upload_path).and_return('/')
      end

      it 'accepts the request and stores the file' do
        expect { subject }.to change { Project.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
      end
    end

    def upload_archive(file, headers = {}, params = {})
      workhorse_finalize(
        api("/projects/import", user),
        method: :post,
        file_key: :file,
        params: params.merge(file: file_upload),
        headers: headers,
        send_rewritten_field: true
      )
    end

    def stub_import(namespace)
      expect_any_instance_of(ProjectImportState).to receive(:schedule)
      expect(::Projects::CreateService).to receive(:new).with(user, hash_including(namespace_id: namespace.id)).and_call_original
    end
  end

  describe 'GET /projects/:id/import' do
    it 'returns the import status' do
      project = create(:project, :import_started)
      project.add_maintainer(user)

      get api("/projects/#{project.id}/import", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include('import_status' => 'started')
    end

    it 'returns the import status and the error if failed' do
      project = create(:project, :import_failed)
      project.add_maintainer(user)
      project.import_state.update(last_error: 'error')

      get api("/projects/#{project.id}/import", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include('import_status' => 'failed',
                                       'import_error' => 'error')
    end
  end

  describe 'POST /projects/import/authorize' do
    subject { post api('/projects/import/authorize', user), headers: workhorse_headers }

    it 'authorizes importing project with workhorse header' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
    end

    it 'rejects requests that bypassed gitlab-workhorse' do
      workhorse_headers.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER)

      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'when using remote storage' do
      context 'when direct upload is enabled' do
        before do
          stub_uploads_object_storage(ImportExportUploader, enabled: true, direct_upload: true)
        end

        it 'responds with status 200, location of file remote store and object details' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(json_response).not_to have_key('TempPath')
          expect(json_response['RemoteObject']).to have_key('ID')
          expect(json_response['RemoteObject']).to have_key('GetURL')
          expect(json_response['RemoteObject']).to have_key('StoreURL')
          expect(json_response['RemoteObject']).to have_key('DeleteURL')
          expect(json_response['RemoteObject']).to have_key('MultipartUpload')
        end
      end

      context 'when direct upload is disabled' do
        before do
          stub_uploads_object_storage(ImportExportUploader, enabled: true, direct_upload: false)
        end

        it 'handles as a local file' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(json_response['TempPath']).to eq(ImportExportUploader.workhorse_local_upload_path)
          expect(json_response['RemoteObject']).to be_nil
        end
      end
    end
  end
end
