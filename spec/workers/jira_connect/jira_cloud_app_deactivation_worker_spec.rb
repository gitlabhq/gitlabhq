# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::JiraCloudAppDeactivationWorker, feature_category: :integrations do
  describe '#perform' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup_1) { create(:group, parent: group) }
    let_it_be(:subgroup_2) { create(:group, parent: group) }
    let_it_be(:project) { create(:project, group: subgroup_1) }

    let_it_be(:group_integration) { create(:jira_cloud_app_integration, :group, group: group) }
    let_it_be(:non_inheriting_asana_integration) do
      create(:asana_integration, :group, group: subgroup_2)
    end

    let_it_be(:non_inheriting_jira_cloud_app_integration) do
      create(:jira_cloud_app_integration, :group, group: subgroup_2)
    end

    let_it_be(:inheriting_jira_cloud_app_integration) do
      create(:jira_cloud_app_integration, :group, group: subgroup_1, inherit_from_id: group_integration.id)
    end

    let_it_be(:inheriting_jira_cloud_app_project_integration) do
      create(:jira_cloud_app_integration, project: project, inherit_from_id: group_integration.id)
    end

    let_it_be(:other_jira_cloud_app_project_integration) do
      create(:jira_cloud_app_integration)
    end

    let_it_be(:other_jira_cloud_app_group_integration) do
      create(:jira_cloud_app_integration, :group)
    end

    subject(:perform) { described_class.new.perform(group.id) }

    before do
      stub_application_setting(jira_connect_application_key: 'mock_key')
    end

    it 'deactivates all subgroup and sub project JiraCloudApp integrations' do
      expect { perform }.not_to change { Integration.count }

      expect(inheriting_jira_cloud_app_integration.reload).not_to be_active
      expect(inheriting_jira_cloud_app_project_integration.reload).not_to be_active
      expect(non_inheriting_jira_cloud_app_integration.reload).not_to be_active
      expect(non_inheriting_asana_integration.reload).to be_active
      expect(other_jira_cloud_app_project_integration.reload).to be_active
      expect(other_jira_cloud_app_group_integration.reload).to be_active
    end
  end
end
