# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectJobTokenScope, feature_category: :secrets_management do
  describe 'GET /projects/:id/job_token_scope' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:user) { create(:user) }

    let(:get_job_token_scope_path) { "/projects/#{project.id}/job_token_scope" }

    subject { get api(get_job_token_scope_path, user) }

    context 'when unauthenticated user (missing user)' do
      context 'for public project' do
        it 'does not return ci cd settings of job token' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

          get api(get_job_token_scope_path)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'when authenticated user as maintainer' do
      before_all { project.add_maintainer(user) }

      it 'returns ci cd settings for job token scope' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(
          "inbound_enabled" => true,
          "outbound_enabled" => false
        )
      end

      it 'returns the correct ci cd settings for job token scope after change' do
        project.update!(ci_inbound_job_token_scope_enabled: false)

        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(
          "inbound_enabled" => false,
          "outbound_enabled" => false
        )
      end

      it 'returns unauthorized and blank response when invalid auth credentials are given' do
        invalid_personal_access_token = build(:personal_access_token, user: user)

        get api(get_job_token_scope_path, user, personal_access_token: invalid_personal_access_token)

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(json_response).not_to include("inbound_enabled", "outbound_enabled")
      end
    end

    context 'when authenticated user as developer' do
      before do
        project.add_developer(user)
      end

      it 'returns forbidden and no ci cd settings for public project' do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

        subject

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response).not_to include("inbound_enabled", "outbound_enabled")
      end
    end
  end
end
