# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IncidentsController, feature_category: :incident_management do
  let_it_be_with_refind(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:anonymous) { nil }

  before do
    sign_in(user) if user
  end

  subject { make_request }

  shared_examples 'not found' do
    include_examples 'returning response status', :not_found
  end

  shared_examples 'login required' do
    it 'redirects to the login page' do
      subject

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'GET #index' do
    def make_request
      get project_incidents_path(project)
    end

    let(:user) { developer }

    it 'shows the page' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end

    context 'when user is unauthorized' do
      let(:user) { anonymous }

      it_behaves_like 'login required'
    end

    context 'when user is a guest' do
      let(:user) { guest }

      it 'shows the page' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end
  end

  describe 'GET #show' do
    def make_request
      get incident_project_issues_path(project, resource)
    end

    let_it_be(:resource) { create(:incident, project: project) }

    let(:user) { developer }

    it 'renders incident page' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:show)

      expect(assigns(:incident)).to be_present
      expect(assigns(:incident).author.association(:status)).to be_loaded
      expect(assigns(:issue)).to be_present
      expect(assigns(:noteable)).to eq(assigns(:incident))
    end

    context 'with non existing id' do
      let(:resource) { non_existing_record_id }

      it_behaves_like 'not found'
    end

    context 'for issue' do
      let_it_be(:resource) { create(:issue, project: project) }

      it_behaves_like 'not found'
    end

    context 'when user is a guest' do
      let(:user) { guest }

      it 'shows the page' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end
    end

    context 'when unauthorized' do
      let(:user) { anonymous }

      it_behaves_like 'login required'
    end
  end
end
