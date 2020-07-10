# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::MergeRequestApprovals do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository, creator: user, namespace: user.namespace) }
  let_it_be(:approver) { create :user }
  let_it_be(:group) { create :group }

  let(:merge_request) { create(:merge_request, :simple, author: user, source_project: project) }

  describe 'GET :id/merge_requests/:merge_request_iid/approvals' do
    it 'retrieves the approval status' do
      project.add_developer(approver)
      project.add_developer(create(:user))

      create(:approval, user: approver, merge_request: merge_request)

      get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", user)

      expect(response).to have_gitlab_http_status(:ok)
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
    end
  end
end
