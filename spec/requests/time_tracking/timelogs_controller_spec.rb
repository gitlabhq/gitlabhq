# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimeTracking::TimelogsController, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }

  describe 'GET #index' do
    subject { get timelogs_path }

    context 'when user is not logged in' do
      it 'responds with a redirect to the login page' do
        subject

        expect(response).to have_gitlab_http_status(:redirect)
      end
    end

    context 'when user is logged in' do
      before do
        sign_in(user)
      end

      context 'when global_time_tracking_report FF is enabled' do
        it 'responds with the global time tracking page', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:index)
        end
      end

      context 'when global_time_tracking_report FF is disable' do
        before do
          stub_feature_flags(global_time_tracking_report: false)
        end

        it 'returns a 404 page' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
