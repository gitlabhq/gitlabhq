# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestAssignee do
  let(:merge_request) { create(:merge_request) }

  subject { merge_request.merge_request_assignees.build(assignee: create(:user)) }

  describe 'associations' do
    it { is_expected.to belong_to(:merge_request).class_name('MergeRequest') }
    it { is_expected.to belong_to(:assignee).class_name('User') }
  end

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:assignee).scoped_to(:merge_request_id) }
  end
end
