require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170523073948_remove_assignee_id_from_issue.rb')

describe RemoveAssigneeIdFromIssue, :migration do
  let(:issues) { table(:issues) }
  let(:issue_assignees) { table(:issue_assignees) }
  let(:users) { table(:users) }

  let!(:user_1) { users.create(email: 'email1@example.com') }
  let!(:user_2) { users.create(email: 'email2@example.com') }
  let!(:user_3) { users.create(email: 'email3@example.com') }

  def create_issue(assignees:)
    issues.create.tap do |issue|
      assignees.each do |assignee|
        issue_assignees.create(issue_id: issue.id, user_id: assignee.id)
      end
    end
  end

  let!(:issue_single_assignee) { create_issue(assignees: [user_1]) }
  let!(:issue_no_assignee) { create_issue(assignees: []) }
  let!(:issue_multiple_assignees) { create_issue(assignees: [user_2, user_3]) }

  describe '#down' do
    it 'sets the assignee_id to a random matching assignee from the assignees table' do
      migrate!
      disable_migrations_output { described_class.new.down }

      expect(issue_single_assignee.reload.assignee_id).to eq(user_1.id)
      expect(issue_no_assignee.reload.assignee_id).to be_nil
      expect(issue_multiple_assignees.reload.assignee_id).to eq(user_2.id).or(user_3.id)

      disable_migrations_output { described_class.new.up }
    end
  end
end
