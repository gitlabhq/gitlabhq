# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectSubscriptions::CreateService, feature_category: :integrations do
  let_it_be(:installation) { create(:jira_connect_installation) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:path) { group.full_path }
  let(:params) { { namespace_path: path, jira_user: jira_user } }
  let(:jira_user) { double(:JiraUser, jira_admin?: true) }

  subject { described_class.new(installation, current_user, params).execute }

  before do
    group.add_maintainer(current_user)
  end

  shared_examples 'a failed execution' do |**status_attributes|
    it 'does not create a subscription' do
      expect { subject }.not_to change { installation.subscriptions.count }
    end

    it 'returns an error status' do
      expect(subject[:status]).to eq(:error)
      expect(subject).to include(status_attributes)
    end
  end

  context 'remote user does not have access' do
    let(:jira_user) { double(jira_admin?: false) }

    it_behaves_like 'a failed execution',
      http_status: 403,
      message: 'The Jira user is not a site or organization administrator. Check the permissions in Jira and try again.'
  end

  context 'remote user cannot be retrieved' do
    let(:jira_user) { nil }

    it_behaves_like 'a failed execution',
      http_status: 403,
      message: 'Could not fetch user information from Jira. Check the permissions in Jira and try again.'
  end

  context 'when user does have access' do
    it 'creates a subscription' do
      expect { subject }.to change { installation.subscriptions.count }.from(0).to(1)
    end

    it 'returns success' do
      expect(subject[:status]).to eq(:success)
    end

    context 'namespace has projects' do
      let_it_be(:project_1) { create(:project, group: group) }
      let_it_be(:project_2) { create(:project, group: group) }

      before do
        stub_const("#{described_class}::MERGE_REQUEST_SYNC_BATCH_SIZE", 1)
      end

      it 'starts workers to sync projects in batches with delay' do
        allow(Atlassian::JiraConnect::Client).to receive(:generate_update_sequence_id).and_return(123)

        expect(JiraConnect::SyncProjectWorker).to receive(:bulk_perform_in).with(1.minute, [[project_1.id, 123]])
        expect(JiraConnect::SyncProjectWorker).to receive(:bulk_perform_in).with(2.minutes, [[project_2.id, 123]])

        subject
      end
    end
  end

  context 'when path is invalid' do
    let(:path) { 'some_invalid_namespace_path' }

    it_behaves_like 'a failed execution',
      http_status: 401,
      message: 'Cannot find namespace. Make sure you have sufficient permissions.'
  end

  context 'when user does not have access' do
    let_it_be(:other_group) { create(:group) }

    let(:path) { other_group.full_path }

    it_behaves_like 'a failed execution',
      http_status: 401,
      message: 'Cannot find namespace. Make sure you have sufficient permissions.'
  end
end
