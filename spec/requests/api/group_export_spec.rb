# frozen_string_literal: true

require 'spec_helper'

describe API::GroupExport do
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
        upload.export_file = fixture_file_upload('spec/fixtures/group_export.tar.gz', "`/tar.gz")
        upload.save!
      end

      it 'downloads exported group archive' do
        get api(download_path, user)

        expect(response).to have_gitlab_http_status(200)
      end

      context 'when export_file.file does not exist' do
        before do
          expect_next_instance_of(ImportExportUploader) do |uploader|
            expect(uploader).to receive(:file).and_return(nil)
          end
        end

        it 'returns 404' do
          get api(download_path, user)

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'when export file does not exist' do
      it 'returns 404' do
        get api(download_path, user)

        expect(response).to have_gitlab_http_status(404)
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

        expect(response).to have_gitlab_http_status(202)
      end
    end

    context 'when user is not a group owner' do
      before do
        group.add_developer(user)
      end

      it 'forbids the request' do
        post api(path, user)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end
end
