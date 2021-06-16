# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectExport, :clean_gitlab_redis_cache do
  let_it_be(:project) { create(:project) }
  let_it_be(:project_none) { create(:project) }
  let_it_be(:project_started) { create(:project) }
  let(:project_finished) { create(:project, :with_export) }
  let(:project_after_export) { create(:project, :with_export) }
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
    shared_examples_for 'get project export status not found' do
      it_behaves_like '404 response' do
        let(:request) { get api(path, user) }
      end
    end

    shared_examples_for 'get project export status denied' do
      it_behaves_like '403 response' do
        let(:request) { get api(path, user) }
      end
    end

    shared_examples_for 'get project export status ok' do
      it 'is none' do
        get api(path_none, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/project/export_status')
        expect(json_response['export_status']).to eq('none')
      end

      context 'when project export has started' do
        before do
          create(:project_export_job, project: project_started, status: 1)
        end

        it 'returns status started' do
          get api(path_started, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/project/export_status')
          expect(json_response['export_status']).to eq('started')
        end
      end

      context 'when project export has finished' do
        it 'returns status finished' do
          get api(path_finished, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/project/export_status')
          expect(json_response['export_status']).to eq('finished')
        end
      end

      context 'when project export is being regenerated' do
        before do
          create(:project_export_job, project: project_finished, status: 1)
        end

        it 'returns status regeneration_in_progress' do
          get api(path_finished, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/project/export_status')
          expect(json_response['export_status']).to eq('regeneration_in_progress')
        end
      end
    end

    it_behaves_like 'when project export is disabled' do
      let(:request) { get api(path, admin) }
    end

    context 'when project export is enabled' do
      context 'when user is an admin' do
        let(:user) { admin }

        it_behaves_like 'get project export status ok'
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
        let(:request) { get api(download_path, user) }
      end
    end

    shared_examples_for 'get project export download denied' do
      it_behaves_like '403 response' do
        let(:request) { get api(download_path, user) }
      end
    end

    shared_examples_for 'get project export download' do
      it_behaves_like '404 response' do
        let(:request) { get api(download_path_none, user) }
      end

      it_behaves_like '404 response' do
        let(:request) { get api(download_path_started, user) }
      end

      it 'downloads' do
        get api(download_path_finished, user)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    shared_examples_for 'get project export upload after action' do
      context 'and is uploading' do
        it 'downloads' do
          get api(download_path_export_action, user)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when export object is not present' do
        before do
          project_after_export.export_file.file.delete
        end

        it 'returns 404' do
          get api(download_path_export_action, user)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('The project export file is not available yet')
        end
      end

      context 'when upload complete' do
        before do
          project_after_export.remove_exports
        end

        it 'has removed the export' do
          expect(project_after_export.export_file_exists?).to be_falsey
        end

        it_behaves_like '404 response' do
          let(:request) { get api(download_path_export_action, user) }
        end
      end
    end

    shared_examples_for 'get project download by strategy' do
      context 'when upload strategy set' do
        it_behaves_like 'get project export upload after action'
      end

      context 'when download strategy set' do
        it_behaves_like 'get project export download'
      end
    end

    it_behaves_like 'when project export is disabled' do
      let(:request) { get api(download_path, admin) }
    end

    context 'when project export is enabled' do
      context 'when user is an admin' do
        let(:user) { admin }

        it_behaves_like 'get project download by strategy'

        context 'when rate limit is exceeded' do
          let(:request) { get api(download_path, admin) }

          before do
            allow(Gitlab::ApplicationRateLimiter)
              .to receive(:increment)
              .and_return(Gitlab::ApplicationRateLimiter.rate_limits[:project_download_export][:threshold].call + 1)
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
    shared_examples_for 'post project export start not found' do
      it_behaves_like '404 response' do
        let(:request) { post api(path, user) }
      end
    end

    shared_examples_for 'post project export start denied' do
      it_behaves_like '403 response' do
        let(:request) { post api(path, user) }
      end
    end

    shared_examples_for 'post project export start' do
      context 'with upload strategy' do
        context 'when params invalid' do
          it_behaves_like '400 response' do
            let(:request) { post(api(path, user), params: { 'upload[url]' => 'whatever' }) }
          end
        end

        it 'starts' do
          allow_any_instance_of(Gitlab::ImportExport::AfterExportStrategies::WebUploadStrategy).to receive(:send_file)

          post(api(path, user), params: { 'upload[url]' => 'http://gitlab.com' })

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

          post api(path, user)

          expect(response).to have_gitlab_http_status(:accepted)
        end

        it 'removes previously exported archive file' do
          expect(project).to receive(:remove_exports).once

          post api(path, user)
        end
      end
    end

    it_behaves_like 'when project export is disabled' do
      let(:request) { post api(path, admin) }
    end

    context 'when project export is enabled' do
      context 'when user is an admin' do
        let(:user) { admin }

        it_behaves_like 'post project export start'

        context 'when rate limit is exceeded across projects' do
          before do
            allow(Gitlab::ApplicationRateLimiter)
              .to receive(:increment)
              .and_return(Gitlab::ApplicationRateLimiter.rate_limits[:project_export][:threshold].call + 1)
          end

          it 'prevents requesting project export' do
            post api(path, admin)

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
        it 'starts', :sidekiq_might_not_need_inline do
          params = { description: "Foo" }

          expect_next_instance_of(Projects::ImportExport::ExportService) do |service|
            expect(service).to receive(:execute)
          end
          post api(path, project.owner), params: params

          expect(response).to have_gitlab_http_status(:accepted)
        end
      end
    end
  end
end
