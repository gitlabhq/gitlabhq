# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Approvable, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let(:user) { create(:user) }

  describe '#approved_by?' do
    subject { merge_request.approved_by?(user) }

    context 'when a user has not approved' do
      it 'returns false' do
        is_expected.to be_falsy
      end
    end

    context 'when a user has approved' do
      let!(:approval) { create(:approval, merge_request: merge_request, user: user) }

      it 'returns false' do
        is_expected.to be_truthy
      end
    end

    context 'when a user is nil' do
      let(:user) { nil }

      it 'returns false' do
        is_expected.to be_falsy
      end
    end
  end

  describe '#approved?' do
    context 'when a merge request is approved' do
      before do
        create(:approval, merge_request: merge_request, user: user)
      end

      it 'returns true' do
        expect(merge_request.approved?).to eq(true)
      end
    end

    context 'when a merge request is not approved' do
      it 'returns false' do
        expect(merge_request.approved?).to eq(false)
      end
    end
  end

  describe '#eligible_for_approval_by?' do
    subject { merge_request.eligible_for_approval_by?(user) }

    before do
      merge_request.project.add_developer(user) if user
    end

    it 'returns true' do
      is_expected.to eq(true)
    end

    context 'when a user has approved' do
      let!(:approval) { create(:approval, merge_request: merge_request, user: user) }

      it 'returns false' do
        is_expected.to eq(false)
      end
    end

    context 'when a user is nil' do
      let(:user) { nil }

      it 'returns false' do
        is_expected.to eq(false)
      end
    end
  end

  describe '#eligible_for_unapproval_by?' do
    subject { merge_request.eligible_for_unapproval_by?(user) }

    before do
      merge_request.project.add_developer(user) if user
    end

    it 'returns false' do
      is_expected.to be_falsy
    end

    context 'when a user has approved' do
      let!(:approval) { create(:approval, merge_request: merge_request, user: user) }

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'when a user is nil' do
      let(:user) { nil }

      it 'returns false' do
        is_expected.to be_falsy
      end
    end
  end

  describe '#approvals_for_user_ids' do
    let_it_be(:user) { create(:user) }
    let_it_be(:merge_request) { create(:merge_request) }
    let_it_be(:approval) { create(:approval, merge_request: merge_request, user: user) }
    let_it_be(:approval2) { create(:approval, merge_request: merge_request, user: create(:user)) }

    subject(:approvals) { merge_request.approvals_for_user_ids([user.id]) }

    it 'returns approvals by user' do
      is_expected.to contain_exactly(approval)
    end
  end

  describe '.not_approved_by_users_with_usernames' do
    subject { MergeRequest.not_approved_by_users_with_usernames([user.username, user2.username]) }

    let!(:merge_request2) { create(:merge_request) }
    let!(:merge_request3) { create(:merge_request) }
    let!(:merge_request4) { create(:merge_request) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    before do
      create(:approval, merge_request: merge_request, user: user)
      create(:approval, merge_request: merge_request2, user: user2)
      create(:approval, merge_request: merge_request2, user: user3)
      create(:approval, merge_request: merge_request4, user: user3)
    end

    it 'has the merge request that is not approved at all and not approved by either user' do
      expect(subject).to contain_exactly(merge_request3, merge_request4)
    end
  end

  describe '.with_existing_approval' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:other_project) { create(:project, :repository) }
    let_it_be(:approver1) { create(:user) }
    let_it_be(:approver2) { create(:user) }

    let_it_be(:merge_request_with_approval) do
      create(:merge_request, source_project: project, source_branch: 'fix')
    end

    let_it_be(:merge_request_with_multiple_approvals) do
      create(:merge_request, source_project: other_project, target_project: other_project)
    end

    let_it_be(:merge_request_without_approval) do
      create(:merge_request, source_project: project, source_branch: 'fix', target_branch: 'staging')
    end

    subject(:scope) { MergeRequest.with_existing_approval }

    before_all do
      create(:approval, merge_request: merge_request_with_approval, user: approver1)
      create(:approval, merge_request: merge_request_with_multiple_approvals, user: approver1)
      create(:approval, merge_request: merge_request_with_multiple_approvals, user: approver2)
    end

    it 'returns merge requests that have at least one approval' do
      expect(scope).to include(merge_request_with_approval, merge_request_with_multiple_approvals)
      expect(scope).not_to include(merge_request_without_approval)
    end

    it 'returns merge requests with multiple approvals only once' do
      expect(scope.where(id: merge_request_with_multiple_approvals.id).count).to eq(1)
    end

    it 'returns an empty result when no merge requests have approvals' do
      Approval.delete_all

      expect(scope).to be_empty
    end

    context 'with performance considerations' do
      it 'uses EXISTS subquery for efficient querying' do
        sql = scope.to_sql

        expect(sql).to include('EXISTS', 'approvals', 'merge_request_id')
      end
    end
  end
end
