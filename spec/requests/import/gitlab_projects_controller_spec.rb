# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GitlabProjectsController do
  include WorkhorseHelpers

  let(:workhorse_token) { JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256') }
  let(:workhorse_headers) { { 'GitLab-Workhorse' => '1.0', Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => workhorse_token } }

  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:user) { namespace.owner }

  before do
    login_as(user)
  end

  describe 'POST create' do
    subject { upload_archive(file_upload, workhorse_headers, params) }

    let(:file) { File.join('spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz') }
    let(:file_upload) { fixture_file_upload(file) }
    let(:params) { { namespace_id: namespace.id, path: 'test' } }

    before do
      allow(ImportExportUploader).to receive(:workhorse_upload_path).and_return('/')
    end

    context 'with a valid path' do
      it 'schedules an import and redirects to the new project path' do
        stub_import(namespace)

        subject

        expect(flash[:notice]).to include('is being imported')
        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'with an invalid path' do
      ['/test', '../test'].each do |invalid_path|
        it "redirects with an error when path is `#{invalid_path}`" do
          params[:path] = invalid_path

          subject

          expect(flash[:alert]).to start_with('Project could not be imported')
          expect(response).to have_gitlab_http_status(:found)
        end
      end
    end

    context 'when request exceeds the rate limit' do
      before do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)
      end

      it 'prevents users from importing projects' do
        subject

        expect(flash[:alert]).to eq('This endpoint has been requested too many times. Try again later.')
        expect(response).to have_gitlab_http_status(:found)
      end
    end

    def upload_archive(file, headers = {}, params = {})
      workhorse_finalize(
        import_gitlab_project_path,
        method: :post,
        file_key: :file,
        params: params.merge(file: file),
        headers: headers,
        send_rewritten_field: true
      )
    end

    def stub_import(namespace)
      expect_any_instance_of(ProjectImportState).to receive(:schedule)
      expect(::Projects::CreateService)
        .to receive(:new)
        .with(user, instance_of(ActionController::Parameters))
        .and_call_original
    end
  end

  describe 'POST authorize' do
    subject { post authorize_import_gitlab_project_path, headers: workhorse_headers }

    it 'authorizes importing project with workhorse header' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      expect(json_response['TempPath']).to eq(ImportExportUploader.workhorse_local_upload_path)
    end

    it 'rejects requests that bypassed gitlab-workhorse' do
      workhorse_headers.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER)

      expect { subject }.to raise_error(JWT::DecodeError)
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
