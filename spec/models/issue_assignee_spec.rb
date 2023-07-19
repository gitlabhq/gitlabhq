# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueAssignee do
  let(:issue) { create(:issue) }

  subject { issue.issue_assignees.build(assignee: create(:user)) }

  describe 'associations' do
    it { is_expected.to belong_to(:issue).class_name('Issue') }
    it { is_expected.to belong_to(:assignee).class_name('User') }
  end

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:assignee).scoped_to(:issue_id) }
  end

  describe 'scopes' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:project_issue) { create(:issue, project: project, assignee_ids: [user.id]) }

    before do
      issue.update!(assignee_ids: [user.id])
    end

    context 'in_projects' do
      it 'returns issue assignees for given project' do
        expect(described_class.count).to eq 2

        assignees = described_class.in_projects([project])

        expect(assignees.count).to eq 1
        expect(assignees.first.user_id).to eq project_issue.issue_assignees.first.user_id
        expect(assignees.first.issue_id).to eq project_issue.issue_assignees.first.issue_id
      end
    end

    context 'on_issues' do
      it 'returns issue assignees for given issues' do
        expect(described_class.count).to eq 2

        assignees = described_class.on_issues([project_issue])

        expect(assignees.count).to eq 1
        expect(assignees.first.issue_id).to eq project_issue.issue_assignees.first.issue_id
      end
    end
  end
end
