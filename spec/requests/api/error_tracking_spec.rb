# frozen_string_literal: true

require 'spec_helper'

describe API::ErrorTracking do
  describe "GET /projects/:id/error_tracking/settings" do
    let(:user) { create(:user) }
    let(:setting) { create(:project_error_tracking_setting) }
    let(:project) { setting.project }

    def make_request
      get api("/projects/#{project.id}/error_tracking/settings", user)
    end

    context 'when authenticated as maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'returns project settings' do
        make_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq(
          'project_name' => setting.project_name,
          'sentry_external_url' => setting.sentry_external_url,
          'api_url' => setting.api_url
        )
      end
    end

    context 'without a project setting' do
      let(:project) { create(:project) }

      before do
        project.add_maintainer(user)
      end

      it 'returns 404' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message'])
          .to eq('404 Error Tracking Setting Not Found')
      end
    end

    context 'when authenticated as reporter' do
      before do
        project.add_reporter(user)
      end

      it 'returns 403' do
        make_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as non-member' do
      it 'returns 404' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      it 'returns 401' do
        make_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
