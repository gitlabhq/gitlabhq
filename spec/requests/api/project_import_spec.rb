# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectImport do
  let(:export_path) { "#{Dir.tmpdir}/project_export_spec" }
  let(:user) { create(:user) }
  let(:file) { File.join('spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz') }
  let(:namespace) { create(:group) }

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

      expect(response).to have_gitlab_http_status(201)
    end

    it 'schedules an import using the namespace path' do
      stub_import(namespace)

      post api('/projects/import', user), params: { path: 'test-import', file: fixture_file_upload(file), namespace: namespace.full_path }

      expect(response).to have_gitlab_http_status(201)
    end

    context 'when a name is explicitly set' do
      let(:expected_name) { 'test project import' }

      it 'schedules an import using a namespace and a different name' do
        stub_import(namespace)

        post api('/projects/import', user), params: { path: 'test-import', file: fixture_file_upload(file), namespace: namespace.id, name: expected_name }

        expect(response).to have_gitlab_http_status(201)
      end

      it 'schedules an import using the namespace path and a different name' do
        stub_import(namespace)

        post api('/projects/import', user), params: { path: 'test-import', file: fixture_file_upload(file), namespace: namespace.full_path, name: expected_name }

        expect(response).to have_gitlab_http_status(201)
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

      expect(response).to have_gitlab_http_status(201)
    end

    it 'does not schedule an import for a namespace that does not exist' do
      expect_any_instance_of(ProjectImportState).not_to receive(:schedule)
      expect(::Projects::CreateService).not_to receive(:new)

      post api('/projects/import', user), params: { namespace: 'nonexistent', path: 'test-import2', file: fixture_file_upload(file) }

      expect(response).to have_gitlab_http_status(404)
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

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Namespace Not Found')
    end

    it 'does not schedule an import if the user uploads no valid file' do
      expect_any_instance_of(ProjectImportState).not_to receive(:schedule)

      post api('/projects/import', user), params: { path: 'test-import3', file: './random/test' }

      expect(response).to have_gitlab_http_status(400)
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

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']).to eq('Name has already been taken')
      end

      context 'when param overwrite is true' do
        it 'schedules an import' do
          stub_import(user.namespace)

          post api('/projects/import', user), params: { path: existing_project.path, file: fixture_file_upload(file), overwrite: true }

          expect(response).to have_gitlab_http_status(201)
        end
      end
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

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to include('import_status' => 'started')
    end

    it 'returns the import status and the error if failed' do
      project = create(:project, :import_failed)
      project.add_maintainer(user)
      project.import_state.update(last_error: 'error')

      get api("/projects/#{project.id}/import", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to include('import_status' => 'failed',
                                       'import_error' => 'error')
    end
  end
end
