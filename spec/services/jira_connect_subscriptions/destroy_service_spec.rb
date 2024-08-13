# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectSubscriptions::DestroyService, feature_category: :integrations do
  describe '#execute' do
    let_it_be(:group) { create(:group, :public, path: 'group') }

    let_it_be(:installation) { create(:jira_connect_installation) }
    let_it_be_with_refind(:subscription) do
      create(:jira_connect_subscription, installation: installation, namespace: group)
    end

    let(:jira_user_is_admin) { true }
    let(:jira_user) { instance_double(Atlassian::JiraConnect::JiraUser, jira_admin?: jira_user_is_admin) }

    subject(:result) { described_class.new(subscription, jira_user).execute }

    context 'when subscription namespace has descendants with inheriting Jira Cloud app integration' do
      it 'destroys the subscription, and schedules JiraCloudAppDeactivationWorker' do
        expect(JiraConnect::JiraCloudAppDeactivationWorker).to receive(:perform_async).with(group.id)

        expect { result }.to change { JiraConnectSubscription.count }.by(-1)

        expect(result).to be_success
      end
    end

    context 'when destroy fails' do
      before do
        allow(subscription).to receive(:destroy).and_return(false)
      end

      it 'returns an error' do
        expect(JiraConnect::JiraCloudAppDeactivationWorker).not_to receive(:perform_async)

        expect { result }.not_to change { JiraConnectSubscription.count }

        expect(result).to be_error
      end
    end

    context 'when subscription is nil' do
      subject(:result) { described_class.new(nil, jira_user).execute }

      it 'returns an error' do
        expect(JiraConnect::JiraCloudAppDeactivationWorker).not_to receive(:perform_async)

        expect { result }.not_to change { JiraConnectSubscription.count }

        expect(result).to be_error
      end
    end

    context 'when the Jira user is not an admin' do
      let(:jira_user_is_admin) { false }

      it 'returns an error with a forbidden message' do
        expect(JiraConnect::JiraCloudAppDeactivationWorker).not_to receive(:perform_async)

        expect { result }.not_to change { JiraConnectSubscription.count }
        expect(result).to be_error
        expect(result.message).to eq('Forbidden')
      end
    end
  end
end
