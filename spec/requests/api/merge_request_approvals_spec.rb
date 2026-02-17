# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::MergeRequestApprovals, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:bot) { create(:user, :project_bot) }
  let_it_be(:project) { create(:project, :public, :repository, creator: user, namespace: user.namespace) }
  let_it_be(:approver) { create :user }
  let(:merge_request) { create(:merge_request, :simple, author: user, source_project: project) }

  describe 'GET :id/merge_requests/:merge_request_iid/approvals' do
    it 'retrieves the approval status' do
      project.add_developer(approver)
      project.add_developer(create(:user))

      create(:approval, user: approver, merge_request: merge_request)

      get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", user)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it_behaves_like 'authorizing granular token permissions', :read_merge_request_approval_state do
      let(:boundary_object) { project }
      let(:request) do
        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", personal_access_token: pat)
      end
    end

    context 'when merge request author has only guest access' do
      it_behaves_like 'rejects user from accessing merge request info' do
        let(:url) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals" }
      end
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/approve' do
    context 'as a valid approver' do
      let_it_be(:approver) { create(:user) }

      before do
        project.add_developer(approver)
        project.add_developer(create(:user))
      end

      def approve(extra_params = {})
        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approve", approver), params: extra_params
      end

      context 'when the publish_review param is not set' do
        it 'approves the merge request' do
          expect(DraftNotes::PublishService).not_to receive(:new)

          approve

          expect(response).to have_gitlab_http_status(:created)
        end

        it_behaves_like 'authorizing granular token permissions', :approve_merge_request do
          let(:boundary_object) { project }
          let(:request) do
            post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approve", personal_access_token: pat)
          end
        end
      end

      context 'when the publish_review param is false' do
        it 'approves the merge request' do
          expect(DraftNotes::PublishService).not_to receive(:new)

          approve(publish_review: false)

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'when the publish_review param is true' do
        it 'approves the merge request' do
          expect_next_instance_of(::DraftNotes::PublishService) do |service|
            expect(service).to receive(:execute).and_call_original
          end

          approve(publish_review: true)

          expect(response).to have_gitlab_http_status(:created)
        end

        context 'when publish service returns an error' do
          it 'returns an error and does not approve the merge request' do
            expect_next_instance_of(::DraftNotes::PublishService) do |service|
              expect(service).to receive(:execute).and_return(ServiceResponse.error(message: 'Error'))
            end

            approve(publish_review: true)

            expect(response).to have_gitlab_http_status(:internal_server_error)
          end
        end
      end

      context 'when the sha param is not set' do
        it 'approves the merge request' do
          approve

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'when the sha param is correct' do
        it 'approves the merge request' do
          approve(sha: merge_request.diff_head_sha)

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'when the sha param is incorrect' do
        it 'does not approve the merge request' do
          approve(sha: merge_request.diff_head_sha.reverse)

          expect(response).to have_gitlab_http_status(:conflict)
          expect(merge_request.approvals).to be_empty
        end
      end
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/unapprove' do
    context 'as a user who has approved the merge request' do
      it 'unapproves the merge request' do
        unapprover = create(:user)

        project.add_developer(approver)
        project.add_developer(unapprover)
        project.add_developer(create(:user))

        create(:approval, user: approver, merge_request: merge_request)
        create(:approval, user: unapprover, merge_request: merge_request)

        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/unapprove", unapprover)

        expect(response).to have_gitlab_http_status(:created)
      end

      it_behaves_like 'authorizing granular token permissions', :unapprove_merge_request do
        let(:boundary_object) { project }

        before do
          project.add_developer(user)
          create(:approval, user: user, merge_request: merge_request)
        end

        let(:request) do
          post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/unapprove", personal_access_token: pat)
        end
      end

      it 'calls MergeRequests::UpdateReviewerStateService' do
        unapprover = create(:user)

        project.add_developer(approver)
        project.add_developer(unapprover)
        project.add_developer(create(:user))

        create(:approval, user: approver, merge_request: merge_request)
        create(:approval, user: unapprover, merge_request: merge_request)

        expect_next_instance_of(
          MergeRequests::UpdateReviewerStateService,
          project: project, current_user: unapprover
        ) do |service|
          expect(service).to receive(:execute).with(merge_request, 'unapproved')
        end

        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/unapprove", unapprover)

        expect(response).to have_gitlab_http_status(:created)
      end
    end
  end

  describe 'PUT :id/merge_requests/:merge_request_iid/reset_approvals' do
    before do
      merge_request.approvals.create!(user: user2)
      create(:project_member, :maintainer, user: bot, source: project)
    end

    context 'for a bot user' do
      context 'when the MR is merged' do
        let(:merge_request) { create(:merge_request, :merged, :simple, author: user, source_project: project) }

        it 'returns 401' do
          put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/reset_approvals", bot)

          merge_request.reload
          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(merge_request.approvals.pluck(:user_id)).to contain_exactly(user2.id)
        end

        it 'does not call log_approval_deletion_on_merged_or_locked_mr' do
          expect_next_found_instance_of(MergeRequest) do |mr|
            expect(mr).not_to receive(:log_approval_deletion_on_merged_or_locked_mr)
          end

          put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/reset_approvals", bot)
        end
      end

      context 'when the MR is open' do
        it 'calls log_approval_deletion_on_merged_or_locked_mr after authorization' do
          expect_next_found_instance_of(MergeRequest) do |mr|
            expect(mr).to receive(:log_approval_deletion_on_merged_or_locked_mr).with(
              source: 'API::MergeRequestApprovals#reset_approvals',
              current_user: bot
            )
          end

          put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/reset_approvals", bot)
        end
      end

      it 'clears approvals of the merge_request' do
        put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/reset_approvals", bot)

        merge_request.reload
        expect(response).to have_gitlab_http_status(:accepted)
        expect(merge_request.approvals).to be_empty
      end

      it_behaves_like 'authorizing granular token permissions', :reset_approvals_merge_request do
        let(:boundary_object) { project }
        let(:user) { bot }
        let(:request) do
          put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/reset_approvals",
            personal_access_token: pat)
        end
      end

      context 'when bot user approved the merge request' do
        before do
          merge_request.approvals.create!(user: bot)
        end

        it 'clears approvals of the merge_request' do
          put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/reset_approvals", bot)

          merge_request.reload
          expect(response).to have_gitlab_http_status(:accepted)
          expect(merge_request.approvals).to be_empty
        end
      end
    end

    context 'for users with non-bot roles' do
      let(:human_user) { create(:user) }

      [:add_owner, :add_maintainer, :add_developer, :add_guest].each do |role_method|
        it 'returns 401' do
          project.send(role_method, human_user)

          put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/reset_approvals", human_user)

          merge_request.reload
          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(merge_request.approvals.pluck(:user_id)).to contain_exactly(user2.id)
        end
      end
    end

    context 'for bot-users from external namespaces' do
      let_it_be(:external_bot) { create(:user, :project_bot) }

      context 'for external group bot-user' do
        before do
          create(:group_member, :maintainer, user: external_bot, source: create(:group))
        end

        it 'returns 401' do
          put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/reset_approvals", external_bot)

          merge_request.reload
          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(merge_request.approvals.pluck(:user_id)).to contain_exactly(user2.id)
        end
      end

      context 'for external project bot-user' do
        before do
          create(:project_member, :maintainer, user: external_bot, source: create(:project))
        end

        it 'returns 401' do
          put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/reset_approvals", external_bot)

          merge_request.reload
          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(merge_request.approvals.pluck(:user_id)).to contain_exactly(user2.id)
        end
      end
    end
  end
end
