# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectSubscriptions::CreateService, feature_category: :integrations do
  let_it_be(:installation) { create(:jira_connect_installation) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, maintainers: current_user) }

  let(:path) { group.full_path }
  let(:params) { { namespace_path: path, jira_user: jira_user } }
  let(:jira_user) { double(:JiraUser, jira_admin?: true) }

  subject { described_class.new(installation, current_user, params).execute }

  shared_examples 'a failed execution' do |**status_attributes|
    it 'does not create a subscription' do
      expect { subject }.not_to change { installation.subscriptions.count }
    end

    it 'returns an error status' do
      expect(subject[:status]).to eq(:error)
      expect(subject).to include(status_attributes)
    end

    it 'does not create jira cloud app integration' do
      expect { subject }.not_to change { Integration.count }
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
    before do
      allow(PropagateIntegrationWorker).to receive(:perform_async)
      stub_application_setting(jira_connect_application_key: 'mock_key')
    end

    it 'creates a subscription' do
      expect { subject }.to change { installation.subscriptions.count }.from(0).to(1)
      expect(subject[:status]).to eq(:success)
    end

    it 'creates an active jira cloud app integration for the group and returns success' do
      expect { subject }.to change { Integrations::JiraCloudApp.for_group(group).count }.from(0).to(1)
      expect(subject[:status]).to eq(:success)

      expect(Integrations::JiraCloudApp.for_group(group).first).to be_active
      expect(PropagateIntegrationWorker).to have_received(:perform_async)
    end

    it 'does not create integration when instance is not configured for Jira Cloud app and returns success' do
      stub_application_setting(jira_connect_application_key: nil)

      expect(subject[:status]).to eq(:success)

      expect { subject }.not_to change { Integrations::JiraCloudApp.count }
      expect(PropagateIntegrationWorker).not_to have_received(:perform_async)
    end

    context 'when group has an existing inactive integration' do
      let_it_be(:integration) { create(:jira_cloud_app_integration, :group, :inactive, group: group) }

      it 'activates the integration' do
        expect { subject }.to change { integration.reload.active }.to eq(true)
      end
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

    context 'when project has non-inheriting inactive jira cloud app integration' do
      let_it_be(:project_1) { create(:project, group: group) }

      let_it_be(:project_integration) do
        create(:jira_cloud_app_integration, :inactive, project: project_1, inherit_from_id: nil)
      end

      it 'activates the integration, but keeps it as non-inheriting' do
        expect { subject }.to change { project_integration.reload.active }.to eq(true)
        expect(project_integration.inherit_from_id).to be_nil
      end
    end
  end

  context 'when group has inheriting inactive jira cloud app integrations' do
    let_it_be(:subgroup_1) { create(:group, parent: group) }
    let_it_be(:subgroup_2) { create(:group, parent: group) }
    let_it_be(:project_1) { create(:project, group: subgroup_1) }
    let_it_be(:group_integration) { create(:jira_cloud_app_integration, :group, :inactive, group: group) }
    let_it_be(:jira_integration) do
      create(:jira_integration, :group, :inactive, group: group, inherit_from_id: group_integration.id)
    end

    let_it_be(:subgroup_integration_1) do
      create(:jira_cloud_app_integration, :group, :inactive, group: subgroup_1, inherit_from_id: group_integration.id)
    end

    let_it_be(:project_integration_1) do
      create(:jira_cloud_app_integration, :inactive, project: project_1, inherit_from_id: group_integration.id)
    end

    before do
      allow(PropagateIntegrationWorker).to receive(:perform_async)
      stub_application_setting(jira_connect_application_key: 'mock_key')
    end

    it 'activate existing jira cloud app integrations if subscription saved successfully' do
      expect(subject[:status]).to eq(:success)

      expect(group_integration.reload).to be_active
      expect(subgroup_integration_1.reload).to be_active
      expect(project_integration_1.reload).to be_active
      expect(jira_integration.reload).not_to be_active
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
