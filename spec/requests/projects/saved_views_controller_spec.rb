# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects::SavedViews', feature_category: :portfolio_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, developer_of: project) }

  before do
    sign_in(user)
    stub_feature_flags(work_items_saved_views: true)
  end

  describe 'GET /projects/:project/-/views/:id' do
    context 'when feature is enabled' do
      context 'when saved view exists' do
        let(:saved_view) { create(:saved_view, namespace: project.project_namespace) }

        subject(:show_saved_view) { get project_saved_view_path(project, saved_view.id) }

        it 'renders the work items index' do
          show_saved_view

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to include('id="js-work-items"')
        end
      end

      context 'when saved view does not exist' do
        subject(:show_saved_view) { get project_saved_view_path(project, 'non-existent-id') }

        it 'renders the work items index' do
          show_saved_view

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to include('id="js-work-items"')
        end
      end
    end

    context 'when feature is disabled' do
      let(:saved_view) { create(:saved_view, namespace: project.project_namespace) }

      subject(:show_saved_view) { get project_saved_view_path(project, saved_view.id) }

      before do
        stub_feature_flags(work_items_saved_views: false)
      end

      it 'returns 404' do
        show_saved_view

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is not authenticated' do
      let(:saved_view) { create(:saved_view, namespace: project.project_namespace) }

      subject(:show_saved_view) { get project_saved_view_path(project, saved_view.id) }

      before do
        sign_out(user)
      end

      it 'redirects to sign in' do
        show_saved_view

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
