# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupExport do
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

    context 'group_import_export feature flag enabled' do
      before do
        stub_feature_flags(group_import_export: true)

        allow(Gitlab::ApplicationRateLimiter)
          .to receive(:increment)
          .and_return(0)
      end

      context 'when export file exists' do
        before do
          upload.export_file = fixture_file_upload('spec/fixtures/group_export.tar.gz', "`/tar.gz")
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
          let(:other_download_path) { "/groups/#{other_group.id}/export/download" }

          before do
            other_group.add_owner(user)
            other_group.export_file.file.delete
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

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'group_import_export feature flag disabled' do
      before do
        stub_feature_flags(group_import_export: false)
      end

      it 'responds with 404 Not Found' do
        get api(download_path, user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the requests have exceeded the rate limit' do
      before do
        allow(Gitlab::ApplicationRateLimiter)
          .to receive(:increment)
          .and_return(Gitlab::ApplicationRateLimiter.rate_limits[:group_download_export][:threshold].call + 1)
      end

      it 'throttles the endpoint' do
        get api(download_path, user)

        expect(json_response["message"])
          .to include('error' => 'This endpoint has been requested too many times. Try again later.')
        expect(response).to have_gitlab_http_status :too_many_requests
      end
    end
  end

  describe 'POST /groups/:group_id/export' do
    context 'group_import_export feature flag enabled' do
      before do
        stub_feature_flags(group_import_export: true)
      end

      context 'when user is a group owner' do
        before do
          group.add_owner(user)
        end

        it 'accepts download' do
          post api(path, user)

          expect(response).to have_gitlab_http_status(:accepted)
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
    end

    context 'group_import_export feature flag disabled' do
      before do
        stub_feature_flags(group_import_export: false)
      end

      it 'responds with 404 Not Found' do
        post api(path, user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the requests have exceeded the rate limit' do
      before do
        group.add_owner(user)

        allow(Gitlab::ApplicationRateLimiter)
          .to receive(:increment)
          .and_return(Gitlab::ApplicationRateLimiter.rate_limits[:group_export][:threshold].call + 1)
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
    let(:path) { "/groups/#{group.id}/export_relations" }
    let(:download_path) { "/groups/#{group.id}/export_relations/download?relation=labels" }
    let(:status_path) { "/groups/#{group.id}/export_relations/status" }

    before do
      stub_feature_flags(group_import_export: true)
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
    end

    describe 'GET /groups/:id/export_relations/download' do
      let(:export) { create(:bulk_import_export, group: group, relation: 'labels') }
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
          allow(upload).to receive(:export_file).and_return(nil)

          get api(download_path, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    describe 'GET /groups/:id/export_relations/status' do
      it 'returns a list of relation export statuses' do
        create(:bulk_import_export, :started, group: group, relation: 'labels')
        create(:bulk_import_export, :finished, group: group, relation: 'milestones')
        create(:bulk_import_export, :failed, group: group, relation: 'badges')

        get api(status_path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('relation')).to contain_exactly('labels', 'milestones', 'badges')
        expect(json_response.pluck('status')).to contain_exactly(-1, 0, 1)
      end
    end
  end
end
