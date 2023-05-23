# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ResourceEvents::AssignmentEventRecorder, feature_category: :value_stream_management do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }

  let_it_be_with_refind(:issue_with_two_assignees) { create(:issue, assignees: [user1, user2]) }
  let_it_be_with_refind(:mr_with_no_assignees) { create(:merge_request) }
  let_it_be_with_refind(:mr_with_one_assignee) { create(:merge_request, assignee: [user3]) }

  let(:parent_records) do
    {
      issue_with_two_assignees: issue_with_two_assignees,
      mr_with_no_assignees: mr_with_no_assignees,
      mr_with_one_assignee: mr_with_one_assignee
    }
  end

  let(:user_records) do
    {
      user1: user1,
      user2: user2,
      user3: user3
    }
  end

  where(:parent, :new_assignees, :assignee_history) do
    :issue_with_two_assignees | [:user1, :user2, :user3] | [[:user3, :add]]
    :issue_with_two_assignees | [:user1, :user3]         | [[:user2, :remove], [:user3, :add]]
    :issue_with_two_assignees | [:user1]                 | [[:user2, :remove]]
    :issue_with_two_assignees | []                       | [[:user1, :remove], [:user2, :remove]]
    :mr_with_no_assignees     | [:user1]                 | [[:user1, :add]]
    :mr_with_no_assignees     | []                       | []
    :mr_with_one_assignee     | [:user3]                 | []
    :mr_with_one_assignee     | [:user1]                 | [[:user3, :remove], [:user1, :add]]
  end

  with_them do
    it 'records the assignment history corrently' do
      parent_record = parent_records[parent]
      old_assignees = parent_record.assignees.to_a
      parent_record.assignees = new_assignees.map { |user_variable_name| user_records[user_variable_name] }

      described_class.new(parent: parent_record, old_assignees: old_assignees).record

      expected_records = assignee_history.map do |user_variable_name, action|
        have_attributes({
          user_id: user_records[user_variable_name].id,
          action: action.to_s
        })
      end

      expect(parent_record.assignment_events).to match_array(expected_records)
    end
  end

  context 'when batching' do
    it 'invokes multiple insert queries' do
      stub_const('Gitlab::ResourceEvents::AssignmentEventRecorder::BATCH_SIZE', 1)

      expect(ResourceEvents::MergeRequestAssignmentEvent).to receive(:insert_all).twice

      described_class.new(parent: mr_with_one_assignee, old_assignees: [user1]).record # 1 assignment, 1 unassignment
    end
  end

  context 'when duplicated old assignees were given' do
    it 'deduplicates the records' do
      expect do
        described_class.new(parent: mr_with_one_assignee, old_assignees: [user3, user2, user2]).record
      end.to change { ResourceEvents::MergeRequestAssignmentEvent.count }.by(1)
    end
  end
end
