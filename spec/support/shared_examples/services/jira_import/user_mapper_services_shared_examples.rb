# frozen_string_literal: true

RSpec.shared_examples 'mapping jira users' do
  let(:client) { double }

  let_it_be(:jira_integration) { create(:jira_integration, project: project, active: true) }

  before do
    allow(subject).to receive(:client).and_return(client)
    allow(client).to receive(:get).with(url).and_return(jira_users)
  end

  subject { described_class.new(current_user, project, start_at) }

  context 'jira_users is nil' do
    let(:jira_users) { nil }

    it 'returns an empty array' do
      expect(subject.execute).to be_empty
    end
  end

  context 'when jira_users is present' do
    let(:mapped_users) do
      [
        { jira_account_id: 'abcd', jira_display_name: 'User-Name1', jira_email: nil, gitlab_id: user_1.id },
        { jira_account_id: 'efg', jira_display_name: 'username-2', jira_email: nil, gitlab_id: user_2.id },
        { jira_account_id: 'hij', jira_display_name: nil, jira_email: nil, gitlab_id: nil },
        { jira_account_id: '123', jira_display_name: 'user-4', jira_email: 'user-4@example.com', gitlab_id: user_4.id },
        { jira_account_id: '456', jira_display_name: 'username5foo', jira_email: 'user-5@example.com', gitlab_id: nil },
        { jira_account_id: '789', jira_display_name: 'user-6', jira_email: 'user-6@example.com', gitlab_id: nil },
        { jira_account_id: 'xyz', jira_display_name: 'username-7', jira_email: 'user-7@example.com', gitlab_id: nil },
        { jira_account_id: 'vhk', jira_display_name: 'user-8', jira_email: 'user8_email@example.com', gitlab_id: user_8.id },
        { jira_account_id: 'uji', jira_display_name: 'user-9', jira_email: 'uji@example.com', gitlab_id: user_1.id }
      ]
    end

    it 'returns users mapped to Gitlab' do
      expect(subject.execute).to eq(mapped_users)
    end

    # 1 query for getting matched users, 3 queries for MembersFinder
    it 'runs only 4 queries' do
      expect { subject }.not_to exceed_query_limit(4)
    end
  end
end
