require 'spec_helper'

describe API::ProjectImport do
  let(:export_path) { "#{Dir.tmpdir}/project_export_spec" }
  let(:user) { create(:user) }
  let(:file) { File.join(Rails.root, 'spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz') }
  let(:namespace) { create(:group) }
  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)

    namespace.add_owner(user)
  end

  after do
    FileUtils.rm_rf(export_path, secure: true)
  end

  describe 'POST /projects/import' do
    it 'schedules an import using a namespace' do
      stub_import(namespace)

      post api('/projects/import', user), path: 'test-import', file: fixture_file_upload(file), namespace: namespace.id

      expect(response).to have_gitlab_http_status(201)
    end

    it 'schedules an import using the namespace path' do
      stub_import(namespace)

      post api('/projects/import', user), path: 'test-import', file: fixture_file_upload(file), namespace: namespace.full_path

      expect(response).to have_gitlab_http_status(201)
    end

    it 'schedules an import at the user namespace level' do
      stub_import(user.namespace)

      post api('/projects/import', user), path: 'test-import2', file: fixture_file_upload(file)

      expect(response).to have_gitlab_http_status(201)
    end

    it 'does not shedule an import for a nampespace that does not exist' do
      expect_any_instance_of(Project).not_to receive(:import_schedule)
      expect(::Projects::CreateService).not_to receive(:new)

      post api('/projects/import', user), namespace: 'nonexistent', path: 'test-import2', file: fixture_file_upload(file)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Namespace Not Found')
    end

    it 'does not schedule an import if the user has no permission to the namespace' do
      expect_any_instance_of(Project).not_to receive(:import_schedule)

      post(api('/projects/import', create(:user)),
           path: 'test-import3',
           file: fixture_file_upload(file),
           namespace: namespace.full_path)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Namespace Not Found')
    end

    it 'does not schedule an import if the user uploads no valid file' do
      expect_any_instance_of(Project).not_to receive(:import_schedule)

      post api('/projects/import', user), path: 'test-import3', file: './random/test'

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('file is invalid')
    end

    it 'stores params that can be overridden' do
      stub_import(namespace)
      override_params = { 'description' => 'Hello world' }

      post api('/projects/import', user),
           path: 'test-import',
           file: fixture_file_upload(file),
           namespace: namespace.id,
           override_params: override_params
      import_project = Project.find(json_response['id'])

      expect(import_project.import_data.data['override_params']).to eq(override_params)
    end

    it 'does not store params that are not allowed' do
      stub_import(namespace)
      override_params = { 'not_allowed' => 'Hello world' }

      post api('/projects/import', user),
           path: 'test-import',
           file: fixture_file_upload(file),
           namespace: namespace.id,
           override_params: override_params
      import_project = Project.find(json_response['id'])

      expect(import_project.import_data.data['override_params']).to be_empty
    end

    it 'correctly overrides params during the import' do
      override_params = { 'description' => 'Hello world' }

      Sidekiq::Testing.inline! do
        post api('/projects/import', user),
             path: 'test-import',
             file: fixture_file_upload(file),
             namespace: namespace.id,
             override_params: override_params
      end
      import_project = Project.find(json_response['id'])

      expect(import_project.description).to eq('Hello world')
    end

    def stub_import(namespace)
      expect_any_instance_of(Project).to receive(:import_schedule)
      expect(::Projects::CreateService).to receive(:new).with(user, hash_including(namespace_id: namespace.id)).and_call_original
    end
  end

  describe 'GET /projects/:id/import' do
    it 'returns the import status' do
      project = create(:project, import_status: 'started')
      project.add_master(user)

      get api("/projects/#{project.id}/import", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to include('import_status' => 'started')
    end

    it 'returns the import status and the error if failed' do
      project = create(:project, import_status: 'failed', import_error: 'error')
      project.add_master(user)

      get api("/projects/#{project.id}/import", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to include('import_status' => 'failed',
                                       'import_error' => 'error')
    end
  end
end
