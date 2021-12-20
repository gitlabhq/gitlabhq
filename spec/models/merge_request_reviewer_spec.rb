# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestReviewer do
  let(:reviewer) { create(:user) }
  let(:merge_request) { create(:merge_request) }

  subject { merge_request.merge_request_reviewers.build(reviewer: reviewer) }

  it_behaves_like 'having unique enum values'

  it_behaves_like 'having reviewer state'

  describe 'syncs to assignee state' do
    before do
      assignee = merge_request.merge_request_assignees.build(assignee: reviewer)
      assignee.update!(state: :reviewed)
    end

    it { is_expected.to have_attributes(state: 'reviewed') }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:merge_request).class_name('MergeRequest') }
    it { is_expected.to belong_to(:reviewer).class_name('User').inverse_of(:merge_request_reviewers) }
  end
end
