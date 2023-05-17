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

  describe 'PATCH /projects/:id/job_token_scope' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:user) { create(:user) }

    let(:patch_job_token_scope_path) { "/projects/#{project.id}/job_token_scope" }
    let(:patch_job_token_scope_params) do
      { enabled: false }
    end

    subject { patch api(patch_job_token_scope_path, user), params: patch_job_token_scope_params }

    context 'when unauthenticated user (missing user)' do
      context 'for public project' do
        it 'does not return ci cd settings of job token' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

          patch api(patch_job_token_scope_path), params: patch_job_token_scope_params

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'when authenticated user as maintainer' do
      before_all { project.add_maintainer(user) }

      it 'returns unauthorized and blank response when invalid auth credentials are given' do
        invalid_personal_access_token = build(:personal_access_token, user: user)

        patch api(patch_job_token_scope_path, user, personal_access_token: invalid_personal_access_token),
          params: patch_job_token_scope_params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns no content and updates the ci cd setting `ci_inbound_job_token_scope_enabled`' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.body).to be_blank

        project.reload

        expect(project.reload.ci_inbound_job_token_scope_enabled?).to be_falsey
        expect(project.reload.ci_outbound_job_token_scope_enabled?).to be_falsey
      end

      it 'returns bad_request when ::Projects::UpdateService fails' do
        project_update_service_result = { status: :error, message: "any_internal_error_message" }
        project_update_service = instance_double(Projects::UpdateService, execute: project_update_service_result)
        allow(::Projects::UpdateService).to receive(:new).and_return(project_update_service)

        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to be_present
      end

      it 'returns bad_request when invalid value for parameter is given' do
        patch api(patch_job_token_scope_path, user), params: {}

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns bad_request when invalid parameter given, e.g. truthy value' do
        patch api(patch_job_token_scope_path, user), params: { enabled: 123 }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns bad_request when invalid parameter given, e.g. `nil`' do
        patch api(patch_job_token_scope_path, user), params: { enabled: nil }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns bad_request and leaves it untouched when unpermitted parameter given' do
        expect do
          patch api(patch_job_token_scope_path, user),
            params: {
              irrelevant_parameter_boolean: true,
              irrelevant_parameter_number: 12.34
            }
        end.not_to change { project.reload.updated_at }

        expect(response).to have_gitlab_http_status(:bad_request)

        project_reloaded = Project.find(project.id)
        expect(project_reloaded.ci_inbound_job_token_scope_enabled?).to eq project.ci_inbound_job_token_scope_enabled?
        expect(project_reloaded.ci_outbound_job_token_scope_enabled?).to eq project.ci_outbound_job_token_scope_enabled?
      end

      # We intend to deprecate the possibility to enable the outbound job token scope until gitlab release `v17.0` .
      it 'returns bad_request when param `outbound_scope_enabled` given' do
        patch api(patch_job_token_scope_path, user), params: { outbound_scope_enabled: true }

        expect(response).to have_gitlab_http_status(:bad_request)

        project.reload

        expect(project.reload.ci_inbound_job_token_scope_enabled?).to be_truthy
        expect(project.reload.ci_outbound_job_token_scope_enabled?).to be_falsey
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
      end
    end
  end
end
