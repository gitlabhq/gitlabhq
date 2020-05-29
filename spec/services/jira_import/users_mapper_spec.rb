# frozen_string_literal: true

require 'spec_helper'

describe JiraImport::UsersMapper do
  let_it_be(:project) { create(:project) }

  subject { described_class.new(project, jira_users).execute }

  describe '#execute' do
    context 'jira_users is nil' do
      let(:jira_users) { nil }

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end

    context 'when jira_users is present' do
      let(:jira_users) do
        [
          { 'accountId' => 'abcd', 'displayName' => 'user1' },
          { 'accountId' => 'efg' },
          { 'accountId' => 'hij', 'displayName' => 'user3', 'emailAddress' => 'user3@example.com' }
        ]
      end

      # TODO: now we only create an array in a proper format
      # mapping is tracked in https://gitlab.com/gitlab-org/gitlab/-/issues/219023
      let(:mapped_users) do
        [
          { jira_account_id: 'abcd', jira_display_name: 'user1', jira_email: nil, gitlab_id: nil },
          { jira_account_id: 'efg', jira_display_name: nil, jira_email: nil, gitlab_id: nil },
          { jira_account_id: 'hij', jira_display_name: 'user3', jira_email: 'user3@example.com', gitlab_id: nil }
        ]
      end

      it 'returns users mapped to Gitlab' do
        expect(subject).to eq(mapped_users)
      end
    end
  end
end
