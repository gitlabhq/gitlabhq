# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectImport, :aggregate_failures, feature_category: :importers do
  include WorkhorseHelpers
  include AfterNextHelpers

  include_context 'workhorse headers'

  let(:user) { create(:user) }
  let(:file) { File.join('spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz') }
  let(:namespace) { create(:group) }

  before do
    namespace.add_owner(user) if user

    stub_application_setting(import_sources: ['gitlab_project'])
  end

  shared_examples 'requires authentication' do
    let(:user) { nil }

    it 'returns 401' do
      subject

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  shared_examples 'requires import source to be enabled' do
    context 'when gitlab_project import_sources is disabled' do
      before do
        stub_application_setting(import_sources: [])
      end

      it 'returns 403' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'POST /projects/import' do
    subject(:perform_archive_upload) { upload_archive(file_upload, workhorse_headers, params) }

    let(:file_upload) { fixture_file_upload(file) }

    let(:params) do
      {
        path: 'test-import',
        'file.size' => file_upload.size
      }
    end

    before do
      allow(ImportExportUploader).to receive(:workhorse_upload_path).and_return('/')
    end

    it_behaves_like 'requires authentication'
    it_behaves_like 'requires import source to be enabled'

    it 'executes a limited number of queries', :use_clean_rails_redis_caching do
      control = ActiveRecord::QueryRecorder.new { perform_archive_upload }

      expect(control.count).to be <= 135
    end

    it 'schedules an import using a namespace' do
      stub_import(namespace)
      params[:namespace] = namespace.id

      perform_archive_upload

      expect(json_response).to include({
        'id' => kind_of(Integer),
        'name' => 'test-import',
        'name_with_namespace' => "#{namespace.name} / test-import",
        'path' => 'test-import',
        'import_type' => 'gitlab_project',
        'path_with_namespace' => "#{namespace.path}/test-import"
      })
      expect(response).to have_gitlab_http_status(:created)
    end

    it 'schedules an import using the namespace path' do
      stub_import(namespace)
      params[:namespace] = namespace.full_path

      perform_archive_upload

      expect(response).to have_gitlab_http_status(:created)
    end

    context 'when a name is explicitly set' do
      let(:expected_name) { 'test project import' }

      it 'schedules an import using a namespace and a different name' do
        stub_import(namespace)
        params[:name] = expected_name
        params[:namespace] = namespace.id

        perform_archive_upload

        expect(response).to have_gitlab_http_status(:created)
      end

      it 'schedules an import using the namespace path and a different name' do
        stub_import(namespace)
        params[:name] = expected_name
        params[:namespace] = namespace.full_path

        perform_archive_upload

        expect(response).to have_gitlab_http_status(:created)
      end

      it 'sets name correctly' do
        stub_import(namespace)
        params[:name] = expected_name
        params[:namespace] = namespace.full_path

        perform_archive_upload

        project = Project.find(json_response['id'])
        expect(project.name).to eq(expected_name)
      end

      it 'sets name correctly with an overwrite' do
        stub_import(namespace)
        params[:name] = 'new project name'
        params[:namespace] = namespace.full_path
        params[:overwrite] = true

        perform_archive_upload

        project = Project.find(json_response['id'])
        expect(project.name).to eq('new project name')
      end

      it 'schedules an import using the path and name explicitly set to nil' do
        stub_import(namespace)
        params[:name] = nil
        params[:namespace] = namespace.full_path

        perform_archive_upload

        project = Project.find(json_response['id'])
        expect(project.name).to eq('test-import')
      end
    end

    context 'when namespace not set' do
      it 'schedules an import at the user namespace level' do
        stub_import(user.namespace)
        params[:path] = 'test-import2'

        perform_archive_upload

        expect(response).to have_gitlab_http_status(:created)
      end

      context 'when current user is a bot user' do
        let(:user) { create(:user, :project_bot) }

        it 'does not schedule an import' do
          expect_any_instance_of(ProjectImportState).not_to receive(:schedule)

          params[:namespace] = nil
          params[:path] = 'test-import3'

          perform_archive_upload

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq("Namespace is not valid")
        end
      end
    end

    it 'does not schedule an import for a namespace that does not exist' do
      expect_any_instance_of(ProjectImportState).not_to receive(:schedule)
      expect(::Projects::CreateService).not_to receive(:new)

      params[:namespace] = 'nonexistent'
      params[:path] = 'test-import2'

      perform_archive_upload

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Namespace Not Found')
    end

    it 'does not schedule an import if the user has no permission to the namespace' do
      expect_any_instance_of(ProjectImportState).not_to receive(:schedule)

      new_namespace = create(:group)
      params[:path] = 'test-import3'
      params[:namespace] = new_namespace.full_path

      perform_archive_upload

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Namespace Not Found')
    end

    context 'when passed in namespace is a bot user namespace' do
      let(:user) { create(:user, :project_bot) }

      it 'does not schedule an import' do
        expect_any_instance_of(ProjectImportState).not_to receive(:schedule)
        params[:namespace] = user.namespace.full_path

        perform_archive_upload

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq("Namespace is not valid")
      end
    end

    context 'if user uploads no valid file' do
      let(:file) { 'README.md' }

      it 'does not schedule an import if the user uploads no valid file' do
        expect_any_instance_of(ProjectImportState).not_to receive(:schedule)

        params[:path] = 'test-import3'

        perform_archive_upload

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']['error']).to eq('You need to upload a GitLab project export archive (ending in .gz).')
      end
    end

    it 'stores params that can be overridden' do
      stub_import(namespace)
      override_params = { 'description' => 'Hello world' }

      params[:namespace] = namespace.id
      params[:override_params] = override_params

      perform_archive_upload

      import_project = Project.find(json_response['id'])

      expect(import_project.import_data.data['override_params']).to eq(override_params)
    end

    it 'does not store params that are not allowed' do
      stub_import(namespace)
      override_params = { 'not_allowed' => 'Hello world' }

      params[:namespace] = namespace.id
      params[:override_params] = override_params

      perform_archive_upload

      import_project = Project.find(json_response['id'])

      expect(import_project.import_data.data['override_params']).to be_empty
    end

    context 'when target path already exists in namespace' do
      let(:existing_project) { create(:project, namespace: user.namespace) }

      it 'does not schedule an import' do
        expect_any_instance_of(ProjectImportState).not_to receive(:schedule)

        params[:path] = existing_project.path

        perform_archive_upload

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq('Path has already been taken')
      end

      context 'when param overwrite is true' do
        it 'schedules an import' do
          stub_import(user.namespace)

          params[:path] = existing_project.path
          params[:overwrite] = true

          perform_archive_upload

          expect(response).to have_gitlab_http_status(:created)
        end
      end
    end

    context 'when request exceeds the rate limit' do
      before do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)
      end

      it 'prevents users from importing projects' do
        params[:namespace] = namespace.id

        perform_archive_upload

        expect(response).to have_gitlab_http_status(:too_many_requests)
        expect(json_response['message']['error']).to eq('This endpoint has been requested too many times. Try again later.')
      end
    end

    context 'when using remote storage' do
      let(:file_name) { 'project_export.tar.gz' }

      let!(:fog_connection) do
        stub_uploads_object_storage(ImportExportUploader, direct_upload: true)
      end

      # rubocop:disable Rails/SaveBang
      let(:tmp_object) do
        fog_connection.directories.new(key: 'uploads').files.create(
          key: "tmp/uploads/#{file_name}",
          body: fixture_file_upload(file)
        )
      end
      # rubocop:enable Rails/SaveBang

      let(:file_upload) { fog_to_uploaded_file(tmp_object) }

      it 'schedules an import' do
        stub_import(namespace)
        params[:namespace] = namespace.id

        perform_archive_upload

        expect(response).to have_gitlab_http_status(:created)
      end
    end

    def upload_archive(file, headers = {}, params = {})
      workhorse_finalize(
        api("/projects/import", user),
        method: :post,
        file_key: :file,
        params: params.merge(file: file),
        headers: headers,
        send_rewritten_field: true
      )
    end

    def stub_import(namespace)
      expect_any_instance_of(ProjectImportState).to receive(:schedule)
      expect(::Projects::CreateService).to receive(:new).with(user, hash_including(namespace_id: namespace.id, import_type: 'gitlab_project')).and_call_original
    end
  end

  describe 'POST /projects/remote-import' do
    subject(:perform_remote_import) do
      post api('/projects/remote-import', user), params: params
    end

    let(:params) do
      {
        path: 'test-import',
        url: 'http://some.s3.url/file'
      }
    end

    it_behaves_like 'requires authentication'
    it_behaves_like 'requires import source to be enabled'

    context 'when the response is successful' do
      it 'schedules the import successfully' do
        project = create(
          :project,
          namespace: user.namespace,
          name: 'test-import',
          path: 'test-import'
        )

        service_response = ServiceResponse.success(payload: project)
        expect_next(::Import::GitlabProjects::CreateProjectService)
          .to receive(:execute)
          .and_return(service_response)

        perform_remote_import

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to include({
          'id' => project.id,
          'name' => 'test-import',
          'name_with_namespace' => "#{user.namespace.name} / test-import",
          'path' => 'test-import',
          'path_with_namespace' => "#{user.namespace.path}/test-import"
        })
      end
    end

    context 'when the service returns an error' do
      it 'fails to schedule the import' do
        service_response = ServiceResponse.error(
          message: 'Failed to import',
          http_status: :bad_request
        )
        expect_next(::Import::GitlabProjects::CreateProjectService)
          .to receive(:execute)
          .and_return(service_response)

        perform_remote_import

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({
          'message' => 'Failed to import'
        })
      end
    end
  end

  describe 'POST /projects/remote-import-s3' do
    subject(:perform_import_from_s3) do
      post api('/projects/remote-import-s3', user), params: params
    end

    let(:params) do
      {
        path: 'test-import',
        region: 'region_name',
        bucket_name: 'bucket_name',
        file_key: 'file_key',
        access_key_id: 'access_key_id',
        secret_access_key: 'secret_access_key'
      }
    end

    it_behaves_like 'requires authentication'
    it_behaves_like 'requires import source to be enabled'

    context 'when the response is successful' do
      it 'schedules the import successfully' do
        project = create(
          :project,
          namespace: user.namespace,
          name: 'test-import',
          path: 'test-import'
        )

        service_response = ServiceResponse.success(payload: project)
        expect_next(::Import::GitlabProjects::CreateProjectService)
          .to receive(:execute)
          .and_return(service_response)

        perform_import_from_s3

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to include({
          'id' => project.id,
          'name' => 'test-import',
          'name_with_namespace' => "#{user.namespace.name} / test-import",
          'path' => 'test-import',
          'path_with_namespace' => "#{user.namespace.path}/test-import"
        })
      end
    end

    context 'when the service returns an error' do
      it 'fails to schedule the import' do
        service_response = ServiceResponse.error(
          message: 'Failed to import',
          http_status: :bad_request
        )
        expect_next(::Import::GitlabProjects::CreateProjectService)
          .to receive(:execute)
          .and_return(service_response)

        perform_import_from_s3

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({
          'message' => 'Failed to import'
        })
      end
    end
  end

  describe 'GET /projects/:id/import' do
    context 'with an unauthenticated user' do
      it 'returns unauthorized response for public project import status' do
        project = create(:project, :public)

        get api("/projects/#{project.id}/import", nil)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

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
      project.import_state.update!(last_error: 'error')

      get api("/projects/#{project.id}/import", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include('import_status' => 'failed', 'import_error' => 'error')
    end

    it 'returns the import status if canceled' do
      project = create(:project, :import_canceled)
      project.add_maintainer(user)

      get api("/projects/#{project.id}/import", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include('import_status' => 'canceled')
    end
  end

  describe 'POST /projects/:id/import-relation' do
    subject(:perform_relation_import) { upload_relation_archive(file_upload, workhorse_headers, params) }

    let(:file_upload) { fixture_file_upload(file) }

    let(:params) do
      {
        path: 'test-import',
        relation: 'issues',
        'file.size' => file_upload.size
      }
    end

    before do
      allow(ImportExportUploader).to receive(:workhorse_upload_path).and_return('/')
    end

    it_behaves_like 'requires authentication'
    it_behaves_like 'requires import source to be enabled'

    it 'executes a limited number of queries', :use_clean_rails_redis_caching do
      control = ActiveRecord::QueryRecorder.new { perform_relation_import }

      expect(control.count).to be <= 111
    end

    context 'when the project is valid' do
      context 'and the user is a maintainer' do
        it 'allows the import' do
          project = create(
            :project,
            name: 'test-import',
            path: 'test-import'
          )

          project.add_maintainer(user)

          params[:path] = project.full_path

          perform_relation_import

          expect(response).to have_gitlab_http_status(:created)
        end
      end
    end

    it 'does not schedule a relation import for a project that does not exist' do
      params[:path] = 'missing/test-import'

      perform_relation_import

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('Project not found')
    end

    it 'does not schedule a relation import if the user has no permission to the project' do
      project = create(
        :project,
        name: 'test-import',
        path: 'test-import'
      )

      params[:path] = project.full_path

      perform_relation_import

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('You are not authorized to perform this action')
    end

    context 'if user uploads no valid file' do
      let(:file) { 'README.md' }

      it 'does not schedule a relation import' do
        params[:path] = 'test-import'

        perform_relation_import

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']['error']).to eq('You need to upload a GitLab project export archive (ending in .gz).')
      end
    end

    context 'when request exceeds the rate limit' do
      before do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)
      end

      it 'prevents users from importing relations' do
        perform_relation_import

        expect(response).to have_gitlab_http_status(:too_many_requests)
        expect(json_response['message']['error']).to eq('This endpoint has been requested too many times. Try again later.')
      end
    end

    def upload_relation_archive(file, headers = {}, params = {})
      workhorse_finalize(
        api("/projects/import-relation", user),
        method: :post,
        file_key: :file,
        params: params.merge(file: file),
        headers: headers,
        send_rewritten_field: true
      )
    end
  end

  describe 'GET /projects/:id/relation-imports' do
    context 'when the user is unauthorized' do
      let_it_be(:project) { create(:project, :public) }

      it 'returns unauthorized response' do
        get api("/projects/#{project.id}/relation-imports", nil)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when the user is not associated with the project' do
      let_it_be(:project) { create(:project, :public) }

      it 'returns unauthorized response' do
        get api("/projects/#{project.id}/relation-imports", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the user is a maintainer on the project' do
      let_it_be_with_reload(:project) do
        project = create(:project)

        project.relation_import_trackers.create!(relation: 'issues')
        project.relation_import_trackers.create!(relation: 'merge_requests')

        project
      end

      let_it_be(:user) { create(:user) }

      before_all do
        project.add_maintainer(user)
      end

      it 'returns an array of import statuses' do
        get api("/projects/#{project.id}/relation-imports", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response.count).to eq(2)
      end

      it 'includes the import status information' do
        get api("/projects/#{project.id}/relation-imports", user)

        expect(json_response.first).to include(
          'relation' => 'issues',
          'status' => 'created'
        )
      end
    end
  end

  describe 'POST /projects/import/authorize' do
    subject(:authorize_import) { post api('/projects/import/authorize', user), headers: workhorse_headers }

    it_behaves_like 'requires authentication'
    it_behaves_like 'requires import source to be enabled'

    it 'authorizes importing project with workhorse header' do
      authorize_import

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.media_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      expect(json_response['TempPath']).to eq(ImportExportUploader.workhorse_local_upload_path)
    end

    it 'rejects requests that bypassed gitlab-workhorse' do
      workhorse_headers.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER)

      authorize_import

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'when using remote storage' do
      context 'when direct upload is enabled' do
        before do
          stub_uploads_object_storage(ImportExportUploader, enabled: true, direct_upload: true)
        end

        it 'responds with status 200, location of file remote store and object details' do
          authorize_import

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
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
          authorize_import

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(json_response['TempPath']).to eq(ImportExportUploader.workhorse_local_upload_path)
          expect(json_response['RemoteObject']).to be_nil
        end
      end
    end
  end

  describe 'POST /projects/import-relation/authorize' do
    subject(:authorize_import) { post api('/projects/import-relation/authorize', user), headers: workhorse_headers }

    it_behaves_like 'requires authentication'
    it_behaves_like 'requires import source to be enabled'

    it 'authorizes importing project with workhorse header' do
      authorize_import

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.media_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      expect(json_response['TempPath']).to eq(ImportExportUploader.workhorse_local_upload_path)
    end

    it 'rejects requests that bypassed gitlab-workhorse' do
      workhorse_headers.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER)

      authorize_import

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end
