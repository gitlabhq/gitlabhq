# frozen_string_literal: true

RSpec.shared_examples 'mapping jira users' do
  let(:client) { double }

  let_it_be(:project) { create(:project) }
  let_it_be(:jira_service) { create(:jira_service, project: project, active: true) }

  before do
    allow(subject).to receive(:client).and_return(client)
    allow(client).to receive(:get).with(url).and_return(jira_users)
  end

  subject { described_class.new(jira_service, start_at) }

  context 'jira_users is nil' do
    let(:jira_users) { nil }

    it 'returns an empty array' do
      expect(subject.execute).to be_empty
    end
  end

  context 'when jira_users is present' do
    # TODO: now we only create an array in a proper format
    # mapping is tracked in https://gitlab.com/gitlab-org/gitlab/-/issues/219023
    let(:mapped_users) do
      [
        { jira_account_id: 'abcd', jira_display_name: 'user1', jira_email: nil, gitlab_id: nil, gitlab_username: nil, gitlab_name: nil },
        { jira_account_id: 'efg', jira_display_name: nil, jira_email: nil, gitlab_id: nil, gitlab_username: nil, gitlab_name: nil },
        { jira_account_id: 'hij', jira_display_name: 'user3', jira_email: 'user3@example.com', gitlab_id: nil, gitlab_username: nil, gitlab_name: nil }
      ]
    end

    it 'returns users mapped to Gitlab' do
      expect(subject.execute).to eq(mapped_users)
    end
  end
end
