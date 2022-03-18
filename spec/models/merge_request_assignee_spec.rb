# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestAssignee do
  let(:assignee) { create(:user) }
  let(:merge_request) { create(:merge_request) }

  subject { merge_request.merge_request_assignees.build(assignee: assignee) }

  describe 'associations' do
    it { is_expected.to belong_to(:merge_request).class_name('MergeRequest') }
    it { is_expected.to belong_to(:assignee).class_name('User') }
  end

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:assignee).scoped_to(:merge_request_id) }
  end

  describe 'scopes' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:project_merge_request) { create(:merge_request, target_project: project, source_project: project, assignee_ids: [user.id]) }

    before do
      merge_request.update!(assignee_ids: [user.id])
    end

    context 'in_projects' do
      it 'returns issue assignees for given project' do
        expect(MergeRequestAssignee.count).to eq 2

        assignees = MergeRequestAssignee.in_projects([project])

        expect(assignees.count).to eq 1
        expect(assignees.first.user_id).to eq project_merge_request.merge_request_assignees.first.user_id
        expect(assignees.first.merge_request_id).to eq project_merge_request.merge_request_assignees.first.merge_request_id
      end
    end
  end

  it_behaves_like 'having unique enum values'

  it_behaves_like 'having reviewer state'

  describe 'syncs to reviewer state' do
    before do
      reviewer = merge_request.merge_request_reviewers.build(reviewer: assignee)
      reviewer.update!(state: :reviewed)
    end

    it { is_expected.to have_attributes(state: 'reviewed') }
  end

  describe '#attention_requested_by' do
    let(:current_user) { create(:user) }

    before do
      subject.update!(updated_state_by: current_user)
    end

    context 'attention requested' do
      it { expect(subject.attention_requested_by).to eq(current_user) }
    end

    context 'attention requested' do
      before do
        subject.update!(state: :reviewed)
      end

      it { expect(subject.attention_requested_by).to eq(nil) }
    end
  end
end
