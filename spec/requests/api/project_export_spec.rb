# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectExport, :aggregate_failures, :clean_gitlab_redis_cache, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:project_none) { create(:project) }
  let_it_be(:project_started) { create(:project) }
  let(:project_finished) { create(:project, :with_export, export_user: user) }
  let(:project_after_export) { create(:project, :with_export, export_user: user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }

  let(:path) { "/projects/#{project.id}/export" }
  let(:path_none) { "/projects/#{project_none.id}/export" }
  let(:path_started) { "/projects/#{project_started.id}/export" }
  let(:path_finished) { "/projects/#{project_finished.id}/export" }
  let(:path_after_export) { "/projects/#{project_after_export.id}/export" }

  let(:download_path) { "/projects/#{project.id}/export/download" }
  let(:download_path_none) { "/projects/#{project_none.id}/export/download" }
  let(:download_path_started) { "/projects/#{project_started.id}/export/download" }
  let(:download_path_finished) { "/projects/#{project_finished.id}/export/download" }
  let(:download_path_export_action) { "/projects/#{project_after_export.id}/export/download" }

  let(:export_path) { "#{Dir.tmpdir}/project_export_spec" }

  before do
    allow(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    allow_next_instance_of(ProjectExportWorker) do |job|
      allow(job).to receive(:jid).and_return(SecureRandom.hex(8))
    end
  end

  after do
    FileUtils.rm_rf(export_path, secure: true)
  end

  shared_examples_for 'when project export is disabled' do
    before do
      stub_application_setting(project_export_enabled?: false)
    end

    it_behaves_like '404 response'
  end

  describe 'GET /projects/:project_id/export' do
    it_behaves_like 'GET request permissions for admin mode' do
      let(:failed_status_code) { :not_found }
    end

    shared_examples_for 'get project export status not found' do
      it_behaves_like '404 response' do
        subject(:request) { get api(path, user) }
      end
    end

    shared_examples_for 'get project export status denied' do
      it_behaves_like '403 response' do
        subject(:request) { get api(path, user) }
      end
    end

    shared_examples_for 'get project export status ok' do
      let_it_be(:admin_mode) { false }

      it 'is none' do
        get api(path_none, user, admin_mode: admin_mode)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/project/export_status')
        expect(json_response['export_status']).to eq('none')
      end

      context 'when project export has started' do
        before do
          create(:project_export_job, project: project_started, status: 1, user: user)
        end

        it 'returns status started' do
          get api(path_started, user, admin_mode: admin_mode)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/project/export_status')
          expect(json_response['export_status']).to eq('started')
        end
      end

      context 'when project export has finished' do
        it 'returns status finished' do
          get api(path_finished, user, admin_mode: admin_mode)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/project/export_status')
          expect(json_response['export_status']).to eq('finished')
        end
      end

      context 'when project export is being regenerated' do
        before do
          create(:project_export_job, project: project_finished, status: 1, user: user)
        end

        it 'returns status regeneration_in_progress' do
          get api(path_finished, user, admin_mode: admin_mode)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/project/export_status')
          expect(json_response['export_status']).to eq('regeneration_in_progress')
        end
      end
    end

    it_behaves_like 'when project export is disabled' do
      subject(:request) { get api(path, admin, admin_mode: true) }
    end

    context 'when project export is enabled' do
      context 'when user is an admin' do
        let(:user) { admin }

        it_behaves_like 'get project export status ok' do
          let(:admin_mode) { true }
        end
      end

      context 'when user is a maintainer' do
        before do
          project.add_maintainer(user)
          project_none.add_maintainer(user)
          project_started.add_maintainer(user)
          project_finished.add_maintainer(user)
          project_after_export.add_maintainer(user)
        end

        it_behaves_like 'get project export status ok'
      end

      context 'when user is a developer' do
        before do
          project.add_developer(user)
        end

        it_behaves_like 'get project export status denied'
      end

      context 'when user is a reporter' do
        before do
          project.add_reporter(user)
        end

        it_behaves_like 'get project export status denied'
      end

      context 'when user is a guest' do
        before do
          project.add_guest(user)
        end

        it_behaves_like 'get project export status denied'
      end

      context 'when user is not a member' do
        it_behaves_like 'get project export status not found'
      end
    end
  end

  describe 'GET /projects/:project_id/export/download' do
    shared_examples_for 'get project export download not found' do
      it_behaves_like '404 response' do
        subject(:request) { get api(download_path, user) }
      end
    end

    shared_examples_for 'get project export download denied' do
      it_behaves_like '403 response' do
        subject(:request) { get api(download_path, user) }
      end
    end

    shared_examples_for 'get project export download' do
      it_behaves_like '404 response' do
        subject(:request) { get api(download_path_none, user, admin_mode: admin_mode) }
      end

      it_behaves_like '404 response' do
        subject(:request) { get api(download_path_started, user, admin_mode: admin_mode) }
      end

      it 'downloads' do
        get api(download_path_finished, user, admin_mode: admin_mode)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    shared_examples_for 'get project export upload after action' do
      context 'and is uploading' do
        it 'downloads' do
          get api(download_path_export_action, user, admin_mode: admin_mode)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when export object is not present' do
        before do
          project_after_export.export_file(user).file.delete
        end

        it 'returns 404' do
          get api(download_path_export_action, user, admin_mode: admin_mode)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('The project export file is not available yet')
        end
      end

      context 'when upload complete' do
        before do
          project_after_export.remove_export_for_user(user)
        end

        it 'has removed the export' do
          expect(project_after_export.export_file_exists?(user)).to be_falsey
        end

        it_behaves_like '404 response' do
          subject(:request) { get api(download_path_export_action, user, admin_mode: admin_mode) }
        end
      end
    end

    shared_examples_for 'get project download by strategy' do
      let_it_be(:admin_mode) { false }

      context 'when upload strategy set' do
        it_behaves_like 'get project export upload after action'
      end

      context 'when download strategy set' do
        it_behaves_like 'get project export download'
      end
    end

    it_behaves_like 'when project export is disabled' do
      subject(:request) { get api(download_path, admin, admin_mode: true) }
    end

    context 'when project export is enabled' do
      context 'when user is an admin' do
        let(:user) { admin }

        it_behaves_like 'get project download by strategy' do
          let(:admin_mode) { true }
        end

        context 'when rate limit is exceeded' do
          subject(:request) { get api(download_path, admin, admin_mode: true) }

          before do
            allow_next_instance_of(Gitlab::ApplicationRateLimiter::BaseStrategy) do |strategy|
              threshold = Gitlab::ApplicationRateLimiter.rate_limits[:project_download_export][:threshold].call
              allow(strategy).to receive(:increment).and_return(threshold + 1)
            end
          end

          it 'prevents requesting project export' do
            request

            expect(response).to have_gitlab_http_status(:too_many_requests)
            expect(json_response['message']['error']).to eq('This endpoint has been requested too many times. Try again later.')
          end
        end

        context 'applies correct scope when throttling' do
          before do
            stub_application_setting(project_download_export_limit: 1)
          end

          it 'throttles downloads within same namespaces', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/413230' do
            # simulate prior request to the same namespace, which increments the rate limit counter for that scope
            Gitlab::ApplicationRateLimiter.throttled?(:project_download_export, scope: [user, project_finished.namespace])

            get api(download_path_finished, user, admin_mode: true)
            expect(response).to have_gitlab_http_status(:too_many_requests)
          end

          it 'allows downloads from different namespaces' do
            # simulate prior request to a different namespace, which increments the rate limit counter for that scope
            Gitlab::ApplicationRateLimiter.throttled?(:project_download_export,
              scope: [user, create(:project, :with_export, export_user: user).namespace])

            get api(download_path_finished, user, admin_mode: true)
            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context 'when user is a maintainer' do
        before do
          project.add_maintainer(user)
          project_none.add_maintainer(user)
          project_started.add_maintainer(user)
          project_finished.add_maintainer(user)
          project_after_export.add_maintainer(user)
        end

        it_behaves_like 'get project download by strategy'
      end

      context 'when user is a developer' do
        before do
          project.add_developer(user)
        end

        it_behaves_like 'get project export download denied'
      end

      context 'when user is a reporter' do
        before do
          project.add_reporter(user)
        end

        it_behaves_like 'get project export download denied'
      end

      context 'when user is a guest' do
        before do
          project.add_guest(user)
        end

        it_behaves_like 'get project export download denied'
      end

      context 'when user is not a member' do
        it_behaves_like 'get project export download not found'
      end
    end

    context 'when an uploader is used' do
      before do
        stub_uploads_object_storage(ImportExportUploader)

        project.add_maintainer(user)
        project_finished.add_maintainer(user)
        project_after_export.add_maintainer(user)

        upload = ImportExportUpload.new(project: project)
        upload.export_file = fixture_file_upload('spec/fixtures/project_export.tar.gz', "`/tar.gz")
        upload.save!
      end

      it_behaves_like 'get project download by strategy'
    end
  end

  describe 'POST /projects/:project_id/export' do
    let(:admin_mode) { false }
    let(:params) { {} }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { { 'upload[url]' => 'http://gitlab.com' } }
      let(:failed_status_code) { :not_found }
      let(:success_status_code) { :accepted }
    end

    subject(:request) { post api(path, user, admin_mode: admin_mode), params: params }

    shared_examples_for 'post project export start not found' do
      it_behaves_like '404 response'
    end

    shared_examples_for 'post project export start denied' do
      it_behaves_like '403 response'
    end

    shared_examples_for 'post project export start' do
      let_it_be(:admin_mode) { false }

      context 'with upload strategy' do
        context 'when params invalid' do
          it_behaves_like '400 response' do
            let(:params) { { 'upload[url]' => 'whatever' } }
          end
        end

        it 'starts' do
          allow_any_instance_of(Gitlab::ImportExport::AfterExportStrategies::WebUploadStrategy).to receive(:send_file)

          request do
            let(:params) { { 'upload[url]' => 'http://gitlab.com' } }
          end

          expect(response).to have_gitlab_http_status(:accepted)
        end
      end

      context 'with download strategy' do
        before do
          Grape::Endpoint.before_each do |endpoint|
            allow(endpoint).to receive(:user_project).and_return(project)
          end
        end

        after do
          Grape::Endpoint.before_each nil
        end

        it 'starts' do
          expect_any_instance_of(Gitlab::ImportExport::AfterExportStrategies::WebUploadStrategy).not_to receive(:send_file)

          request

          expect(response).to have_gitlab_http_status(:accepted)
        end

        it 'removes previously exported archive file' do
          expect(project).to receive(:remove_export_for_user).with(user).once

          request
        end
      end
    end

    it_behaves_like 'when project export is disabled'

    context 'when project export is enabled' do
      context 'when user is an admin' do
        let(:user) { admin }
        let(:admin_mode) { true }

        it_behaves_like 'post project export start' do
          let(:admin_mode) { true }
        end

        context 'with project export size limit' do
          before do
            stub_application_setting(max_export_size: 1)
          end

          it 'starts if limit not exceeded' do
            request

            expect(response).to have_gitlab_http_status(:accepted)
          end

          it '400 response if limit exceeded' do
            project.statistics.update!(lfs_objects_size: 2.megabytes, repository_size: 2.megabytes)

            request

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response["message"]).to include('The project size exceeds the export limit.')
          end
        end

        context 'when rate limit is exceeded across projects' do
          before do
            allow_next_instance_of(Gitlab::ApplicationRateLimiter::BaseStrategy) do |strategy|
              threshold = Gitlab::ApplicationRateLimiter.rate_limits[:project_export][:threshold].call
              allow(strategy).to receive(:increment).and_return(threshold + 1)
            end
          end

          it 'prevents requesting project export' do
            request

            expect(response).to have_gitlab_http_status(:too_many_requests)
            expect(json_response['message']['error']).to eq('This endpoint has been requested too many times. Try again later.')
          end
        end
      end

      context 'when user is a maintainer' do
        before do
          project.add_maintainer(user)
          project_none.add_maintainer(user)
          project_started.add_maintainer(user)
          project_finished.add_maintainer(user)
          project_after_export.add_maintainer(user)
        end

        it_behaves_like 'post project export start'
      end

      context 'when user is a developer' do
        before do
          project.add_developer(user)
        end

        it_behaves_like 'post project export start denied'
      end

      context 'when user is a reporter' do
        before do
          project.add_reporter(user)
        end

        it_behaves_like 'post project export start denied'
      end

      context 'when user is a guest' do
        before do
          project.add_guest(user)
        end

        it_behaves_like 'post project export start denied'
      end

      context 'when user is not a member' do
        it_behaves_like 'post project export start not found'
      end

      context 'when overriding description' do
        let(:params) { { description: "Foo" } }

        it 'enqueues CreateRelationExportsWorker' do
          expect(Projects::ImportExport::CreateRelationExportsWorker).to receive(:perform_async).with(
            project.first_owner.id,
            project.id,
            nil,
            { description: "Foo", exported_by_admin: false }
          )

          post api(path, project.first_owner), params: params
          expect(response).to have_gitlab_http_status(:accepted)
        end
      end
    end
  end

  describe 'export relations' do
    let(:relation) { 'labels' }
    let(:download_path) { "/projects/#{project.id}/export_relations/download?relation=#{relation}" }
    let(:path) { "/projects/#{project.id}/export_relations" }

    let_it_be(:status_path) { "/projects/#{project.id}/export_relations/status" }

    before do
      stub_application_setting(bulk_import_enabled: true)
    end

    context 'when user is a maintainer' do
      before do
        project.add_maintainer(user)
      end

      describe 'POST /projects/:id/export_relations' do
        it 'accepts the request' do
          post api(path, user)

          expect(response).to have_gitlab_http_status(:accepted)
        end

        context 'when response is not success' do
          it 'returns api error' do
            allow_next_instance_of(BulkImports::ExportService) do |service|
              allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'error', http_status: :error))
            end

            post api(path, user)

            expect(response).to have_gitlab_http_status(:error)
          end
        end

        context 'when request is to export in batches' do
          it 'accepts the request' do
            expect(BulkImports::ExportService)
              .to receive(:new)
              .with(portable: project, user: user, batched: true)
              .and_call_original

            post api(path, user), params: { batched: true }

            expect(response).to have_gitlab_http_status(:accepted)
          end
        end
      end

      describe 'GET /projects/:id/export_relations/download' do
        context 'when export request is not batched' do
          let_it_be(:export) { create(:bulk_import_export, project: project, relation: 'labels', user: user) }
          let_it_be(:upload) { create(:bulk_import_export_upload, export: export) }

          context 'when export file exists' do
            it 'downloads exported project relation archive' do
              upload.update!(export_file: fixture_file_upload('spec/fixtures/bulk_imports/gz/labels.ndjson.gz'))

              get api(download_path, user)

              expect(response).to have_gitlab_http_status(:ok)
              expect(response.header['Content-Disposition']).to eq("attachment; filename=\"labels.ndjson.gz\"; filename*=UTF-8''labels.ndjson.gz")
            end
          end

          context 'when relation is not portable' do
            let(:relation) { ::BulkImports::FileTransfer::ProjectConfig.new(project).skipped_relations.first }

            it_behaves_like '400 response' do
              subject(:request) { get api(download_path, user) }
            end
          end

          context 'when export file does not exist' do
            it 'returns 404' do
              allow(upload).to receive(:export_file).and_return(nil)

              get api(download_path, user)

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end

          context 'when export is batched' do
            let(:relation) { 'issues' }

            let_it_be(:export) { create(:bulk_import_export, :batched, project: project, relation: 'issues', user: user) }

            it 'returns 400' do
              export.update!(batched: true)

              get api(download_path, user)

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response['message']).to eq('Export is batched')
            end
          end
        end

        context 'when export request is batched' do
          let(:export) { create(:bulk_import_export, :batched, project: project, relation: 'labels', user: user) }
          let(:upload) { create(:bulk_import_export_upload) }
          let!(:batch) { create(:bulk_import_export_batch, export: export, upload: upload) }

          it 'downloads exported batch' do
            upload.update!(export_file: fixture_file_upload('spec/fixtures/bulk_imports/gz/labels.ndjson.gz'))

            get api(download_path, user), params: { batched: true, batch_number: batch.batch_number }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.header['Content-Disposition']).to eq("attachment; filename=\"labels.ndjson.gz\"; filename*=UTF-8''labels.ndjson.gz")
          end

          context 'when request is to download not batched export' do
            it 'returns 400' do
              get api(download_path, user)

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response['message']).to eq('Export is batched')
            end
          end

          context 'when batch cannot be found' do
            it 'returns 404' do
              get api(download_path, user), params: { batched: true, batch_number: 0 }

              expect(response).to have_gitlab_http_status(:not_found)
              expect(json_response['message']).to eq('Batch not found')
            end
          end

          context 'when batch file cannot be found' do
            it 'returns 404' do
              batch.upload.destroy!

              get api(download_path, user), params: { batched: true, batch_number: batch.batch_number }

              expect(response).to have_gitlab_http_status(:not_found)
              expect(json_response['message']).to eq('Batch file not found')
            end
          end
        end
      end

      describe 'GET /projects/:id/export_relations/status' do
        let_it_be(:started_export) { create(:bulk_import_export, :started, project: project, relation: 'labels', user: user) }
        let_it_be(:finished_export) { create(:bulk_import_export, :finished, project: project, relation: 'milestones', user: user) }
        let_it_be(:failed_export) { create(:bulk_import_export, :failed, project: project, relation: 'project_badges', user: user) }

        it 'returns a list of relation export statuses' do
          get api(status_path, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.pluck('relation')).to contain_exactly('labels', 'milestones', 'project_badges')
          expect(json_response.pluck('status')).to contain_exactly(-1, 0, 1)
          expect(json_response.pluck('batched')).to all(eq(false))
          expect(json_response.pluck('batches_count')).to all(eq(0))
        end

        context 'when relation is specified' do
          it 'return a single relation export status' do
            get api(status_path, user), params: { relation: 'labels' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['relation']).to eq('labels')
            expect(json_response['status']).to eq(0)
          end
        end

        context 'when there is a batched export' do
          let_it_be(:batched_export) do
            create(:bulk_import_export, :started, :batched, project: project, relation: 'issues', batches_count: 1, user: user)
          end

          let_it_be(:batch) { create(:bulk_import_export_batch, objects_count: 5, export: batched_export) }

          it 'returns a list of batched relation export statuses' do
            get api(status_path, user)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to include(
              hash_including(
                'relation' => batched_export.relation,
                'batched' => true,
                'batches_count' => 1,
                'batches' => contain_exactly(
                  {
                    'batch_number' => 1,
                    'error' => nil,
                    'objects_count' => batch.objects_count,
                    'status' => batch.status,
                    'updated_at' => batch.updated_at.as_json
                  }
                )
              )
            )
          end
        end

        context 'when the export was started by another user' do
          let_it_be(:other_user) { create(:user) }

          before_all do
            project.add_maintainer(other_user)
          end

          it 'returns not_found when a relation was specified' do
            get api(status_path, other_user), params: { relation: 'labels' }

            expect(response).to have_gitlab_http_status(:not_found)
          end

          it 'does not appear in the list of all statuses' do
            get api(status_path, other_user)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_empty
          end
        end
      end

      context 'with bulk_import is disabled' do
        before do
          stub_application_setting(bulk_import_enabled: false)
        end

        describe 'POST /projects/:id/export_relations' do
          it_behaves_like '404 response' do
            let(:message) { '404 Not Found' }

            subject(:request) { post api(path, user) }
          end
        end

        describe 'GET /projects/:id/export_relations/download' do
          let_it_be(:export) { create(:bulk_import_export, project: project, relation: 'labels', user: user) }
          let_it_be(:upload) { create(:bulk_import_export_upload, export: export) }

          before do
            upload.update!(export_file: fixture_file_upload('spec/fixtures/bulk_imports/gz/labels.ndjson.gz'))
          end

          it_behaves_like '404 response' do
            let(:message) { '404 Not Found' }

            subject(:request) { get api(download_path, user) }
          end
        end

        describe 'GET /projects/:id/export_relations/status' do
          it_behaves_like '404 response' do
            let(:message) { '404 Not Found' }

            subject(:request) { get api(status_path, user) }
          end
        end
      end
    end

    context 'when user is a developer' do
      let_it_be(:developer) { create(:user) }

      before do
        project.add_developer(developer)
      end

      describe 'POST /projects/:id/export_relations' do
        it_behaves_like '403 response' do
          subject(:request) { post api(path, developer) }
        end
      end

      describe 'GET /projects/:id/export_relations/download' do
        it_behaves_like '403 response' do
          subject(:request) { get api(download_path, developer) }
        end
      end

      describe 'GET /projects/:id/export_relations/status' do
        it_behaves_like '403 response' do
          subject(:request) { get api(status_path, developer) }
        end
      end
    end
  end
end
