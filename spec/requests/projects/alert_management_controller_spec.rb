# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AlertManagementController, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:id) { 1 }

  before_all do
    project.add_developer(developer)
    project.add_reporter(reporter)
  end

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    context 'when user is authorized' do
      let(:user) { developer }

      it 'shows the page' do
        get project_alert_management_index_path(project)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when user is unauthorized' do
      let(:user) { reporter }

      it 'shows 404' do
        get project_alert_management_index_path(project)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #details' do
    context 'when user is authorized' do
      let(:user) { developer }

      it 'shows the page' do
        get project_alert_management_alert_path(project, id)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'sets alert id from the route' do
        get project_alert_management_alert_path(project, id)

        expect(assigns(:alert_id)).to eq(id.to_s)
      end
    end

    context 'when user is unauthorized' do
      let(:user) { reporter }

      it 'shows 404' do
        get project_alert_management_alert_path(project, id)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
