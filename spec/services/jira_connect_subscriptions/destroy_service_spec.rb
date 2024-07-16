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
      let_it_be(:subgroup_1) { create(:group, parent: group) }
      let_it_be(:subgroup_2) { create(:group, parent: group) }
      let_it_be(:project_1) { create(:project, group: subgroup_1) }

      let_it_be(:group_integration) { create(:jira_cloud_app_integration, :group, group: group) }
      let_it_be(:non_inheriting_asana_integration) do
        create(:asana_integration, :group, group: subgroup_2, inherit_from_id: nil)
      end

      let_it_be(:non_inheriting_jira_cloud_app_integration) do
        create(:jira_cloud_app_integration, :group, group: subgroup_2, inherit_from_id: nil)
      end

      let_it_be(:inheriting_jira_cloud_app_integration) do
        create(:jira_cloud_app_integration, :group, group: subgroup_1, inherit_from_id: group_integration.id)
      end

      let_it_be(:inheriting_jira_cloud_app_project_integration) do
        create(:jira_cloud_app_integration, project: project_1, inherit_from_id: group_integration.id)
      end

      it 'destroys the subscription, deactivates the integration, and schedules PropagateIntegrationWorker' do
        expect { result }.to change { JiraConnectSubscription.count }.by(-1)
        expect(inheriting_jira_cloud_app_integration.reload).not_to be_active
        expect(inheriting_jira_cloud_app_project_integration.reload).not_to be_active
        expect(non_inheriting_jira_cloud_app_integration.reload).not_to be_active
        expect(non_inheriting_asana_integration.reload).to be_active
        expect(result).to be_success
      end
    end

    context 'when subscription namespace does not have a Jira Cloud app integration' do
      let_it_be(:other_integration) { create(:jira_cloud_app_integration) }

      it 'destroys the subscription but does not schedule PropagateIntegrationWorker' do
        expect { result }.to change { JiraConnectSubscription.count }.by(-1)
        expect(other_integration.reload).to be_active
        expect(result).to be_success
      end
    end

    context 'when destroy fails' do
      before do
        allow(subscription).to receive(:destroy).and_return(false)
      end

      it 'returns an error' do
        expect(Integration).not_to receive(:descendants_from_self_or_ancestors_from)

        expect { result }.not_to change { JiraConnectSubscription.count }
        expect(result).to be_error
      end
    end

    context 'when subscription is nil' do
      subject(:result) { described_class.new(nil, jira_user).execute }

      it 'returns an error' do
        expect(Integration).not_to receive(:descendants_from_self_or_ancestors_from)

        expect { result }.not_to change { JiraConnectSubscription.count }
        expect(result).to be_error
      end
    end

    context 'when the Jira user is not an admin' do
      let(:jira_user_is_admin) { false }

      it 'returns an error with a forbidden message' do
        expect(Integration).not_to receive(:descendants_from_self_or_ancestors_from)

        expect { result }.not_to change { JiraConnectSubscription.count }
        expect(result).to be_error
        expect(result.message).to eq('Forbidden')
      end
    end
  end
end
