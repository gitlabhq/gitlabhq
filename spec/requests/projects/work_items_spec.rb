# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work Items', feature_category: :team_planning do
  include WorkhorseHelpers

  include_context 'workhorse headers'

  let_it_be(:work_item) { create(:work_item) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:file) { fixture_file_upload("spec/fixtures/#{filename}") }

  before_all do
    work_item.project.add_developer(current_user)
  end

  shared_examples 'response with 404 status' do
    it 'returns 404' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'safely handles uploaded files' do
    it 'ensures the upload is handled safely', :aggregate_failures do
      allow(Gitlab::PathTraversal).to receive(:check_path_traversal!).and_call_original
      expect(Gitlab::PathTraversal).to receive(:check_path_traversal!).with(filename).at_least(:once)
      expect(FileUploader).not_to receive(:cache)

      subject
    end
  end

  describe 'GET /:namespace/:project/-/work_items' do
    context 'when the user can read the project' do
      before do
        sign_in(current_user)
      end

      it 'renders index' do
        get project_work_items_url(work_item.project)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when the work_item_planning_view feature flag is disabled' do
      before do
        sign_in(current_user)
        stub_feature_flags(work_item_planning_view: false)
      end

      it 'returns not found' do
        get project_work_items_url(work_item.project)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'for work_items_client_side_boards feature flag' do
      before do
        sign_in(current_user)
        stub_feature_flags(work_items_client_side_boards: current_user, work_item_planning_view: true)
      end

      it 'provides the feature flag set to true' do
        get project_work_items_url(work_item.project)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to have_pushed_frontend_feature_flags(workItemsClientSideBoards: true)
      end

      context 'when disabled' do
        before do
          stub_feature_flags(work_items_client_side_boards: false, work_item_planning_view: true)
        end

        it 'provides the feature flag set to false' do
          get project_work_items_url(work_item.project)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to have_pushed_frontend_feature_flags(workItemsClientSideBoards: false)
        end
      end
    end

    context 'when the user cannot read the project' do
      before do
        sign_in(current_user)
        work_item.project.team.truncate
      end

      it 'returns not found' do
        get project_work_items_path(work_item.project)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /:namespace/:project/-/work_items.ics' do
    let(:work_items_path) { project_work_items_url(work_item.project, format: :ics) }

    context 'when using token access' do
      context 'on public projects' do
        let(:public_project) { create(:project, :public) }

        it_behaves_like 'authenticates sessionless user for the request spec', 'calendar ics', public_resource: true do
          let(:url) { project_work_items_url(public_project, format: :ics) }

          before do
            public_project.add_maintainer(user)
          end
        end
      end

      context 'on private projects' do
        let(:private_project) { create(:project, :private) }

        it_behaves_like 'authenticates sessionless user for the request spec',
          'calendar ics',
          public_resource: false,
          ignore_metrics: true do
            let(:url) { project_work_items_url(private_project, format: :ics) }

            before do
              private_project.add_maintainer(user)
            end
          end
      end
    end

    context 'when the user can read the project' do
      before do
        sign_in(current_user)
      end

      it 'renders calendar' do
        get work_items_path

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Type']).to have_content('text/calendar')
        expect(response.body).to have_text('BEGIN:VCALENDAR')
      end
    end

    context 'when the user cannot read the project' do
      before do
        sign_in(current_user)
        work_item.project.team.truncate
      end

      it 'returns not found' do
        get work_items_path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /:namespace/:project/work_items/:id' do
    context 'when authenticated' do
      before do
        sign_in(current_user)
      end

      it 'renders show' do
        get project_work_item_url(work_item.project, work_item.iid)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'has correct metadata' do
        get project_work_item_url(work_item.project, work_item.iid)

        expect(response.body).to include("#{work_item.title} (#{work_item.to_reference})")
        expect(response.body).to include(work_item.work_item_type.name.pluralize)
      end
    end

    context 'when user cannot read the project' do
      before do
        sign_in(current_user)
        work_item.project.team.truncate
      end

      it 'renders not found' do
        get project_work_item_url(work_item.project, work_item.iid)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not include sensitive metadata' do
        get project_work_item_url(work_item.project, work_item.iid)

        expect(response.body).not_to include("#{work_item.title} (#{work_item.to_reference})")
        expect(response.body).not_to include(work_item.work_item_type.name.pluralize)
      end
    end
  end

  describe 'POST /:namespace/:project/work_items/import_csv' do
    let(:filename) { 'work_items_valid_types.csv' }
    let(:params) { { namespace_id: project.namespace.id, path: 'test' } }

    subject { upload_file(file, workhorse_headers, params) }

    shared_examples 'handles authorisation' do
      context 'when unauthorized' do
        context 'with non-member' do
          let_it_be(:current_user) { create(:user) }

          before do
            sign_in(current_user)
          end

          it 'responds with error' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'with anonymous user' do
          it 'responds with error' do
            subject

            expect(response).to have_gitlab_http_status(:found)
            expect(response).to be_redirect
          end
        end
      end

      context 'when authorized' do
        before do
          sign_in(current_user)
          project.add_reporter(current_user)
        end

        context 'when import/export work items feature is available and member is a reporter' do
          shared_examples 'response with success status' do
            it 'returns 200 status and success message' do
              subject

              expect(response).to have_gitlab_http_status(:success)
              expect(json_response).to eq(
                'message' => "Your work items are being imported. Once finished, you'll receive a confirmation email.")
            end
          end

          it_behaves_like 'response with success status'
          it_behaves_like 'safely handles uploaded files'

          it 'shows error when upload fails' do
            expect_next_instance_of(UploadService) do |upload_service|
              expect(upload_service).to receive(:execute).and_return(nil)
            end

            subject

            expect(json_response).to eq('errors' => 'File upload error.')
          end

          context 'when file extension is not csv' do
            let(:filename) { 'sample_doc.md' }

            it 'returns error message' do
              subject

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response).to eq(
                'errors' => "The uploaded file was invalid. Supported file extensions are .csv.")
            end
          end
        end

        context 'when work items import/export feature is not available' do
          before do
            stub_feature_flags(work_items_project_issues_list: false)
          end

          it_behaves_like 'response with 404 status'
        end
      end
    end

    context 'with public project' do
      let_it_be(:project) { create(:project, :public) }

      it_behaves_like 'handles authorisation'
    end

    context 'with private project' do
      it_behaves_like 'handles authorisation'
    end

    def upload_file(file, headers = {}, params = {})
      workhorse_finalize(
        import_csv_project_work_items_path(project),
        method: :post,
        file_key: :file,
        params: params.merge(file: file),
        headers: headers,
        send_rewritten_field: true
      )
    end
  end

  describe 'POST #authorize' do
    subject do
      post import_csv_authorize_project_work_items_path(project),
        headers: workhorse_headers
    end

    before do
      sign_in(current_user)
    end

    context 'with authorized user' do
      before do
        project.add_reporter(current_user)
      end

      context 'when work items import/export feature is enabled' do
        let(:user) { current_user }

        it_behaves_like 'handle uploads authorize request' do
          let(:uploader_class) { FileUploader }
          let(:maximum_size) { Gitlab::CurrentSettings.max_attachment_size.megabytes }
        end
      end

      context 'when work_items_project_issues_list is disabled' do
        before do
          stub_feature_flags(work_items_project_issues_list: false)
        end

        it_behaves_like 'response with 404 status'
      end
    end

    context 'with unauthorized user' do
      it_behaves_like 'response with 404 status'
    end
  end
end
