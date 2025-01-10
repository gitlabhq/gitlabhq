# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupExport, feature_category: :importers do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:path) { "/groups/#{group.id}/export" }
  let(:download_path) { "/groups/#{group.id}/export/download" }

  let(:export_path) { "#{Dir.tmpdir}/group_export_spec" }

  before do
    allow_next_instance_of(Gitlab::ImportExport) do |import_export|
      expect(import_export).to receive(:storage_path).and_return(export_path)
    end
  end

  after do
    FileUtils.rm_rf(export_path, secure: true)
  end

  describe 'GET /groups/:group_id/export/download' do
    let(:upload) { ImportExportUpload.new(group: group) }

    before do
      stub_uploads_object_storage(ImportExportUploader)

      group.add_owner(user)
    end

    context 'when export file exists' do
      before do
        allow_next_instance_of(Gitlab::ApplicationRateLimiter::BaseStrategy) do |strategy|
          allow(strategy).to receive(:increment).and_return(0)
          allow(strategy).to receive(:read).and_return(0)
        end

        upload.export_file = fixture_file_upload('spec/fixtures/group_export.tar.gz', "`/tar.gz")
        upload.user = user
        upload.save!
      end

      it 'downloads exported group archive' do
        get api(download_path, user)

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when export_file.file does not exist' do
        before do
          expect_next_instance_of(ImportExportUploader) do |uploader|
            expect(uploader).to receive(:file).and_return(nil)
          end
        end

        it 'returns 404' do
          get api(download_path, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when object is not present' do
        let(:other_group) { create(:group, :with_export) }
        let!(:export) { create(:import_export_upload, user: user, group: other_group) }
        let(:other_download_path) { "/groups/#{other_group.id}/export/download" }

        before do
          other_group.add_owner(user)
          other_group.export_file(user).file.delete
        end

        it 'returns 404' do
          get api(other_download_path, user)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('The group export file is not available yet')
        end
      end
    end

    context 'when export file does not exist' do
      it 'returns 404' do
        get api(download_path, user)

        allow(Gitlab::ApplicationRateLimiter)
          .to receive(:increment)
          .and_return(0)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the requests have exceeded the rate limit' do
      before do
        allow(Gitlab::ApplicationRateLimiter)
          .to receive(:increment)
          .and_return(Gitlab::ApplicationRateLimiter.rate_limits[:group_download_export][:threshold].call + 1)
      end

      it 'throttles the endpoint', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/448732' do
        get api(download_path, user)

        expect(json_response["message"])
          .to include('error' => 'This endpoint has been requested too many times. Try again later.')
        expect(response).to have_gitlab_http_status :too_many_requests
      end
    end
  end

  describe 'POST /groups/:group_id/export' do
    context 'when user is a group owner' do
      before do
        group.add_owner(user)
      end

      it 'accepts download' do
        post api(path, user)

        expect(response).to have_gitlab_http_status(:accepted)
      end

      it 'calls the service correctly' do
        expect_next_instance_of(Groups::ImportExport::ExportService,
          group: group,
          user: user,
          exported_by_admin: false
        ) do |service|
          expect(service).to receive(:async_execute).and_return(true)
        end

        post api(path, user)
      end

      context 'when user is an admin', :enable_admin_mode do
        let_it_be(:user) { create(:admin) }

        it 'calls the service correctly' do
          expect_next_instance_of(Groups::ImportExport::ExportService,
            group: group,
            user: user,
            exported_by_admin: true
          ) do |service|
            expect(service).to receive(:async_execute).and_return(true)
          end

          post api(path, user)
        end
      end
    end

    context 'when the export cannot be started' do
      before do
        group.add_owner(user)
        allow(GroupExportWorker).to receive(:perform_async).and_return(nil)
      end

      it 'returns an error' do
        post api(path, user)

        expect(response).to have_gitlab_http_status(:error)
      end
    end

    context 'when user is not a group owner' do
      before do
        group.add_developer(user)
      end

      it 'forbids the request' do
        post api(path, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the requests have exceeded the rate limit' do
      before do
        group.add_owner(user)

        allow_next_instance_of(Gitlab::ApplicationRateLimiter::BaseStrategy) do |strategy|
          allow(strategy)
            .to receive(:increment)
            .and_return(Gitlab::ApplicationRateLimiter.rate_limits[:group_export][:threshold].call + 1)
        end
      end

      it 'throttles the endpoint' do
        post api(path, user)

        expect(json_response["message"])
          .to include('error' => 'This endpoint has been requested too many times. Try again later.')
        expect(response).to have_gitlab_http_status :too_many_requests
      end
    end
  end

  describe 'relations export' do
    let(:relation) { 'labels' }
    let(:path) { "/groups/#{group.id}/export_relations" }
    let(:download_path) { "/groups/#{group.id}/export_relations/download?relation=#{relation}" }
    let(:status_path) { "/groups/#{group.id}/export_relations/status" }

    before do
      stub_application_setting(bulk_import_enabled: true)

      group.add_owner(user)
    end

    describe 'POST /groups/:id/export_relations' do
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
            .with(portable: group, user: user, batched: true)
            .and_call_original

          post api(path, user), params: { batched: true }

          expect(response).to have_gitlab_http_status(:accepted)
        end
      end
    end

    describe 'GET /groups/:id/export_relations/download' do
      context 'when export request is not batched' do
        let(:export) { create(:bulk_import_export, group: group, relation: 'labels', user: user) }
        let(:upload) { create(:bulk_import_export_upload, export: export) }

        context 'when export file exists' do
          it 'downloads exported group archive' do
            upload.update!(export_file: fixture_file_upload('spec/fixtures/bulk_imports/gz/labels.ndjson.gz'))

            get api(download_path, user)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when export_file.file does not exist' do
          it 'returns 404' do
            allow(export).to receive(:upload).and_return(nil)

            get api(download_path, user)

            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response['message']).to eq('Export file not found')
          end
        end

        context 'when export is batched' do
          let(:relation) { 'milestones' }

          let_it_be(:export) { create(:bulk_import_export, :batched, group: group, relation: 'milestones', user: user) }

          it 'returns 400' do
            export.update!(batched: true)

            get api(download_path, user)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq('Export is batched')
          end
        end
      end

      context 'when export request is batched' do
        let(:export) { create(:bulk_import_export, :batched, group: group, relation: 'labels', user: user) }
        let(:upload) { create(:bulk_import_export_upload) }
        let!(:batch) { create(:bulk_import_export_batch, export: export, upload: upload) }

        it 'downloads exported batch' do
          upload.update!(export_file: fixture_file_upload('spec/fixtures/bulk_imports/gz/labels.ndjson.gz'))

          get api(download_path, user), params: { batched: true, batch_number: batch.batch_number }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.header['Content-Disposition'])
            .to eq("attachment; filename=\"labels.ndjson.gz\"; filename*=UTF-8''labels.ndjson.gz")
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

    describe 'GET /groups/:id/export_relations/status' do
      let_it_be(:started_export) { create(:bulk_import_export, :started, group: group, relation: 'labels', user: user) }
      let_it_be(:finished_export) do
        create(:bulk_import_export, :finished, group: group, relation: 'milestones', user: user)
      end

      let_it_be(:failed_export) { create(:bulk_import_export, :failed, group: group, relation: 'badges', user: user) }

      it 'returns a list of relation export statuses' do
        get api(status_path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('relation')).to contain_exactly('labels', 'milestones', 'badges')
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
          create(
            :bulk_import_export,
            :started,
            :batched,
            group: group,
            relation: 'boards',
            batches_count: 1,
            user: user
          )
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
          group.add_owner(other_user)
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

    context 'when bulk import is disabled' do
      subject(:request) { post api(path, user) }

      before do
        stub_application_setting(bulk_import_enabled: false)
      end

      it_behaves_like '404 response' do
        let(:message) { '404 Not Found' }
      end
    end
  end
end
