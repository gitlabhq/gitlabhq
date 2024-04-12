# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GitlabProjectsController, feature_category: :importers do
  include WorkhorseHelpers

  include_context 'workhorse headers'

  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:user) { namespace.first_owner }

  before do
    login_as(user)

    stub_application_setting(import_sources: ['gitlab_project'])
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
    it_behaves_like 'handle uploads authorize request' do
      let(:uploader_class) { ImportExportUploader }
      let(:maximum_size) { Gitlab::CurrentSettings.max_import_size.megabytes }

      subject { post authorize_import_gitlab_project_path, headers: workhorse_headers }
    end
  end

  describe 'GET new' do
    context 'when the user is not allowed to import projects' do
      let!(:group) { create(:group, developers: user) }

      it 'returns 404' do
        get new_import_gitlab_project_path, params: { namespace_id: group.id }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
