# frozen_string_literal: true

require 'spec_helper'

describe IssueAssignee do
  let(:issue) { create(:issue) }

  subject { issue.issue_assignees.build(assignee: create(:user)) }

  describe 'associations' do
    it { is_expected.to belong_to(:issue).class_name('Issue') }
    it { is_expected.to belong_to(:assignee).class_name('User') }
  end

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:assignee).scoped_to(:issue_id) }
  end
end
