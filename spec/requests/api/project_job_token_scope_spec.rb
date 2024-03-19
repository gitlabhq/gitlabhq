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

  describe "GET /projects/:id/job_token_scope/allowlist" do
    let_it_be(:project) { create(:project, :public) }

    let_it_be(:user) { create(:user) }

    let(:get_job_token_scope_allowlist_path) { "/projects/#{project.id}/job_token_scope/allowlist" }

    subject { get api(get_job_token_scope_allowlist_path, user) }

    context 'when unauthenticated user (missing user)' do
      context 'for public project' do
        it 'does not return ci cd settings of job token' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

          get api(get_job_token_scope_allowlist_path)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'when authenticated user as maintainer' do
      before_all { project.add_maintainer(user) }

      it 'returns allowlist containing only the source projects' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_present
        expect(json_response).to include hash_including("id" => project.id)
      end

      it 'returns allowlist of project' do
        create(:ci_job_token_project_scope_link, source_project: project, direction: :inbound)
        create(:ci_job_token_project_scope_link, source_project: project, direction: :outbound)

        ci_job_token_project_scope_link =
          create(
            :ci_job_token_project_scope_link,
            source_project: project,
            direction: :inbound
          )

        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq 3
        expect(json_response).to include(
          hash_including("id" => project.id),
          hash_including("id" => ci_job_token_project_scope_link.target_project.id)
        )
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

  describe "GET /projects/:id/job_token_scope/groups_allowlist" do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:target_group) { create(:group, :public) }

    let_it_be(:user) { create(:user) }

    let(:get_job_token_scope_groups_allowlist_path) { "/projects/#{project.id}/job_token_scope/groups_allowlist" }

    subject { get api(get_job_token_scope_groups_allowlist_path, user) }

    context 'when unauthenticated user (missing user)' do
      context 'for public project' do
        it 'does not return ci cd settings of job token' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

          get api(get_job_token_scope_groups_allowlist_path)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'when authenticated user as maintainer' do
      before_all { project.add_maintainer(user) }

      it 'returns allowlist containing empty groups list' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_empty
      end

      it 'returns groups allowlist of project' do
        create(:ci_job_token_group_scope_link, source_project: project, target_group: target_group)

        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq 1
        expect(json_response).to include(
          hash_including("id" => target_group.id)
        )
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

  describe "POST /projects/:id/job_token_scope/groups_allowlist" do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:target_group) { create(:group, :public) }
    let_it_be(:user) { create(:user) }

    let(:post_job_token_scope_groups_allowlist_path) { "/projects/#{project.id}/job_token_scope/groups_allowlist" }

    let(:post_job_token_scope_groups_allowlist_params) do
      { target_group_id: target_group.id }
    end

    subject do
      post api(post_job_token_scope_groups_allowlist_path, user), params: post_job_token_scope_groups_allowlist_params
    end

    context 'when unauthenticated user (missing user)' do
      context 'for public project' do
        it 'does not return ci cd settings of job token' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

          post api(post_job_token_scope_groups_allowlist_path)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'when authenticated user as maintainer' do
      before_all { project.add_maintainer(user) }

      it 'returns unauthorized and blank response when invalid auth credentials are given' do
        invalid_personal_access_token = build(:personal_access_token, user: user)

        post api(post_job_token_scope_groups_allowlist_path, user,
          personal_access_token: invalid_personal_access_token),
          params: post_job_token_scope_groups_allowlist_params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns created and creates job token scope link' do
        subject

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to be_present
        expect(json_response).to include(
          "target_group_id" => target_group.id,
          "source_project_id" => project.id
        )
      end

      it 'returns bad_request and does not create an additional job token scope link' do
        create(
          :ci_job_token_group_scope_link,
          source_project: project,
          target_group: target_group
        )

        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns not_found when group for param `target_group_id` does not exist' do
        post api(post_job_token_scope_groups_allowlist_path, user), params: { target_group_id: non_existing_record_id }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns :bad_request when parameter `target_group_id` missing' do
        post api(post_job_token_scope_groups_allowlist_path, user), params: {}

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns :bad_request when parameter `target_group_id` is nil value' do
        post api(post_job_token_scope_groups_allowlist_path, user), params: { target_group_id: nil }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns :bad_request when parameter `target_group_id` is empty value' do
        post api(post_job_token_scope_groups_allowlist_path, user), params: { target_group_id: '' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when authenticated user as developer' do
      before_all { project.add_developer(user) }

      context 'for private project' do
        it 'returns forbidden and no ci cd settings' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'for public project' do
        it 'returns forbidden and no ci cd settings' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'DELETE /projects/:id/job_token_scope/groups_allowlist/:target_group_id' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:target_group) { create(:group, :public) }
    let_it_be(:user) { create(:user) }
    let_it_be(:link) do
      create(:ci_job_token_group_scope_link,
        source_project: project,
        target_group: target_group)
    end

    let(:project_id) { project.id }
    let(:delete_job_token_scope_groups_allowlist_path) do
      "/projects/#{project_id}/job_token_scope/groups_allowlist/#{target_group.id}"
    end

    subject { delete api(delete_job_token_scope_groups_allowlist_path, user) }

    context 'when unauthenticated user (missing user)' do
      let(:user) { nil }

      context 'for public project' do
        it 'does not delete requested project from groups allowlist' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'when user has no permissions to project' do
      it 'responds with 401 forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated user as a developer' do
      before do
        project.add_developer(user)
      end

      it 'returns 403 Forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated user as a maintainer' do
      before do
        project.add_maintainer(user)
      end

      context 'for the target project member' do
        before do
          target_group.add_guest(user)
        end

        it 'returns no content and deletes requested project from groups allowlist' do
          expect_next_instance_of(
            Ci::JobTokenScope::RemoveGroupService,
            project,
            user
          ) do |service|
            expect(service).to receive(:execute).with(target_group)
              .and_return(instance_double('ServiceResponse', success?: true))
          end

          subject

          expect(response).to have_gitlab_http_status(:no_content)
          expect(response.body).to be_blank
        end

        context 'when fails to remove target group' do
          it 'returns a bad request' do
            expect_next_instance_of(
              Ci::JobTokenScope::RemoveGroupService,
              project,
              user
            ) do |service|
              expect(service).to receive(:execute).with(target_group)
                .and_return(instance_double('ServiceResponse',
                  success?: false,
                  reason: nil,
                  message: 'Failed to remove'))
            end

            subject

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'when user project does not exists' do
        before do
          project.destroy!
        end

        it 'responds with 404 Not found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when target group does not exists' do
        before do
          target_group.destroy!
        end

        it 'responds with 404 Not found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe "POST /projects/:id/job_token_scope/allowlist" do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:project_inbound_allowed) { create(:project, :public) }
    let_it_be(:user) { create(:user) }

    let(:post_job_token_scope_allowlist_path) { "/projects/#{project.id}/job_token_scope/allowlist" }

    let(:post_job_token_scope_allowlist_params) do
      { target_project_id: project_inbound_allowed.id }
    end

    subject do
      post api(post_job_token_scope_allowlist_path, user), params: post_job_token_scope_allowlist_params
    end

    context 'when unauthenticated user (missing user)' do
      context 'for public project' do
        it 'does not return ci cd settings of job token' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

          post api(post_job_token_scope_allowlist_path)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'when authenticated user as maintainer' do
      before_all { project.add_maintainer(user) }

      it 'returns unauthorized and blank response when invalid auth credentials are given' do
        invalid_personal_access_token = build(:personal_access_token, user: user)

        post api(post_job_token_scope_allowlist_path, user, personal_access_token: invalid_personal_access_token),
          params: post_job_token_scope_allowlist_params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns created and creates job token scope link' do
        subject

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to be_present
        expect(json_response).to include(
          "target_project_id" => project_inbound_allowed.id,
          "source_project_id" => project.id
        )
        expect(json_response).not_to include "id", "direction"
      end

      it 'returns bad_request and does not create an additional job token scope link' do
        create(
          :ci_job_token_project_scope_link,
          source_project: project,
          target_project: project_inbound_allowed,
          direction: :inbound
        )

        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns bad_request when adding the source project' do
        post api(post_job_token_scope_allowlist_path, user), params: { target_project_id: project.id }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns not_found when project for param `project_id` does not exist' do
        post api(post_job_token_scope_allowlist_path, user), params: { target_project_id: non_existing_record_id }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns :bad_request when parameter `project_id` missing' do
        post api(post_job_token_scope_allowlist_path, user), params: {}

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns :bad_request when parameter `project_id` is nil value' do
        post api(post_job_token_scope_allowlist_path, user), params: { target_project_id: nil }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns :bad_request when parameter `project_id` is empty value' do
        post api(post_job_token_scope_allowlist_path, user), params: { target_project_id: '' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns :bad_request when parameter `project_id` is float value' do
        post api(post_job_token_scope_allowlist_path, user), params: { target_project_id: 12.34 }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when authenticated user as developer' do
      before_all { project.add_developer(user) }

      context 'for private project' do
        it 'returns forbidden and no ci cd settings' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'for public project' do
        it 'returns forbidden and no ci cd settings' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'DELETE /projects/:id/job_token_scope/allowlist/:target_project_id' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:target_project) { create(:project, :public) }
    let_it_be(:user) { create(:user) }
    let_it_be(:link) do
      create(:ci_job_token_project_scope_link,
        source_project: project,
        target_project: target_project)
    end

    let(:project_id) { project.id }
    let(:delete_job_token_scope_path) do
      "/projects/#{project_id}/job_token_scope/allowlist/#{target_project.id}"
    end

    subject { delete api(delete_job_token_scope_path, user) }

    context 'when unauthenticated user (missing user)' do
      let(:user) { nil }

      context 'for public project' do
        it 'does not delete requested project from allowlist' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'when user has no permissions to project' do
      it 'responds with 401 forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated user as a developer' do
      before do
        project.add_developer(user)
      end

      it 'returns 403 Forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated user as a maintainer' do
      before do
        project.add_maintainer(user)
      end

      context 'for the target project member' do
        before do
          target_project.add_guest(user)
        end

        it 'returns no content and deletes requested project from allowlist' do
          expect_next_instance_of(
            Ci::JobTokenScope::RemoveProjectService,
            project,
            user
          ) do |service|
            expect(service).to receive(:execute).with(target_project, :inbound)
              .and_return(instance_double('ServiceResponse', success?: true))
          end

          subject

          expect(response).to have_gitlab_http_status(:no_content)
          expect(response.body).to be_blank
        end

        context 'when fails to remove target project' do
          it 'returns a bad request' do
            expect_next_instance_of(
              Ci::JobTokenScope::RemoveProjectService,
              project,
              user
            ) do |service|
              expect(service).to receive(:execute).with(target_project, :inbound)
                .and_return(instance_double('ServiceResponse',
                  success?: false,
                  reason: nil,
                  message: 'Failed to remove'))
            end

            subject

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'when user project does not exists' do
        before do
          project.destroy!
        end

        it 'responds with 404 Not found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when target project does not exists' do
        before do
          target_project.destroy!
        end

        it 'responds with 404 Not found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
