# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Propagation::BulkCreateService, feature_category: :integrations do
  include JiraIntegrationHelpers

  before_all do
    stub_jira_integration_test
  end

  let_it_be(:excluded_group) { create(:group) }
  let_it_be(:excluded_project) { create(:project, group: excluded_group) }

  let(:instance_integration) { create(:jira_integration, :instance) }
  let(:excluded_attributes) do
    %w[
      id project_id group_id inherit_from_id instance template
      created_at updated_at
      encrypted_properties encrypted_properties_iv organization_id project_id group_id
    ]
  end

  subject(:execute_service) { described_class.new(integration, batch, association).execute }

  shared_examples 'creates integration successfully' do
    def attributes(record)
      record.reload.attributes.except(*excluded_attributes)
    end

    it 'updates the inherited integrations' do
      execute_service

      expect(attributes(created_integration)).to eq attributes(integration)
    end

    context 'when integration has data fields' do
      let(:excluded_attributes) do
        %w[
          id service_id integration_id created_at updated_at
          organization_id group_id project_id
        ]
      end

      it 'updates the data fields from inherited integrations' do
        execute_service

        expect(attributes(created_integration.data_fields))
          .to eq attributes(integration.data_fields)
      end

      it 'sets created_at and updated_at timestamps', :freeze_time do
        execute_service

        expect(created_integration.data_fields.reload).to have_attributes(
          created_at: eq(Time.current),
          updated_at: eq(Time.current)
        )
      end
    end

    context 'when integration has organization' do
      let(:excluded_attributes) do
        %w[
          id project_id group_id inherit_from_id instance template
          created_at updated_at
          encrypted_properties encrypted_properties_iv organization_id
          group_id project_id
        ]
      end

      it 'does not propagate organization' do
        execute_service

        expect(instance_integration.organization).not_to be_nil
        expect(created_integration.organization).to be_nil
      end
    end

    it 'updates inherit_from_id attributes' do
      execute_service

      expect(created_integration.reload.inherit_from_id).to eq(inherit_from_id)
    end

    it 'sets created_at and updated_at timestamps', :freeze_time do
      execute_service

      expect(created_integration.reload).to have_attributes(
        created_at: eq(Time.current),
        updated_at: eq(Time.current)
      )
    end
  end

  shared_examples 'creates GitLab for Slack app data successfully' do
    it 'creates associated SlackIntegration record and scopes' do
      inherited_slack_integration = integration.slack_integration

      execute_service

      expect(created_integration.reload.slack_integration).to have_attributes(
        team_id: inherited_slack_integration.team_id,
        team_name: inherited_slack_integration.team_name,
        alias: expected_alias,
        user_id: inherited_slack_integration.user_id,
        bot_user_id: inherited_slack_integration.bot_user_id,
        bot_access_token: inherited_slack_integration.bot_access_token,
        created_at: be_present,
        updated_at: be_present,
        authorized_scope_names: inherited_slack_integration.authorized_scope_names
      )
    end

    context 'when integration is disabled' do
      before do
        integration.update!(active: false)
      end

      it 'does not create associated SlackIntegration record' do
        execute_service

        expect(created_integration.reload.slack_integration).to be_nil
      end
    end
  end

  context 'with an instance-level integration' do
    let_it_be(:organization) { create(:common_organization) }
    let(:integration) { instance_integration }
    let(:inherit_from_id) { integration.id }

    let_it_be_with_reload(:instance_slack_integration) do
      create(:gitlab_slack_application_integration, :instance,
        organization_id: organization.id,
        slack_integration: build(:slack_integration,
          team_id: 'instance_team_id',
          team_name: 'instance_team_name',
          alias: 'instance_alias',
          bot_access_token: 'instance_bot_access_token',
          authorized_scope_names: %w[instance_scope1 instance_scope2],
          organization_id: organization.id
        )
      )
    end

    context 'with a project association' do
      let!(:project) { create(:project) }
      let(:created_integration) { Integration.find_by(project: project) }
      let(:batch) { Project.where(id: project.id) }
      let(:association) { 'project' }

      it_behaves_like 'creates integration successfully'

      it_behaves_like 'creates GitLab for Slack app data successfully' do
        let(:integration) { instance_slack_integration }
        let(:expected_alias) { project.full_path }

        it 'sets the project ID on the newly created slack integration' do
          execute_service

          expect(created_integration.slack_integration.project_id).to eq(project.id)
          expect(created_integration.slack_integration.group_id).to be_nil
          expect(created_integration.slack_integration.organization_id).to be_nil
        end
      end
    end

    context 'with a group association' do
      let!(:group) { create(:group) }
      let(:created_integration) { Integration.find_by(group: group) }
      let(:batch) { Group.where(id: group.id) }
      let(:association) { 'group' }

      it_behaves_like 'creates integration successfully'

      it_behaves_like 'creates GitLab for Slack app data successfully' do
        let(:integration) { instance_slack_integration }
        let(:expected_alias) { group.full_path }

        it 'sets the group ID on the newly created slack integration' do
          execute_service

          expect(created_integration.slack_integration.project_id).to be_nil
          expect(created_integration.slack_integration.group_id).to eq(group.id)
          expect(created_integration.slack_integration.organization_id).to be_nil
        end
      end
    end
  end

  context 'with a group-level integration' do
    let_it_be(:group) { create(:group) }

    let_it_be_with_reload(:group_slack_integration) do
      create(:gitlab_slack_application_integration, :group,
        group: group,
        slack_integration: build(:slack_integration,
          team_id: 'group_team_id',
          team_name: 'group_team_name',
          alias: 'group_alias',
          bot_access_token: 'group_bot_access_token',
          authorized_scope_names: %w[group_scope1 group_scope2],
          group: group
        )
      )
    end

    context 'with a project association' do
      let!(:project) { create(:project, group: group) }
      let(:integration) { create(:jira_integration, :group, group: group) }
      let(:created_integration) { Integration.find_by(project: project) }
      let(:batch) { Project.without_integration(integration).in_namespace(integration.group.self_and_descendants) }
      let(:association) { 'project' }
      let(:inherit_from_id) { integration.id }

      it_behaves_like 'creates integration successfully'

      it 'sets project_id in data_fields' do
        execute_service

        expect(created_integration.data_fields.project_id).to eq(project.id)
        expect(created_integration.data_fields.group_id).to be_nil
        expect(created_integration.data_fields.organization_id).to be_nil
      end

      context 'with different foreign key of data_fields' do
        let(:integration) { create(:zentao_integration, :group, group: group) }

        it_behaves_like 'creates integration successfully'
      end

      it_behaves_like 'creates GitLab for Slack app data successfully' do
        let(:integration) { group_slack_integration }
        let(:expected_alias) { project.full_path }

        it 'sets the project ID on the newly created slack integration' do
          execute_service

          expect(created_integration.slack_integration.project_id).to eq(project.id)
          expect(created_integration.slack_integration.group_id).to be_nil
          expect(created_integration.slack_integration.organization_id).to be_nil
        end
      end
    end

    context 'with a group association' do
      let!(:subgroup) { create(:group, parent: group) }
      let(:integration) { create(:jira_integration, :group, group: group, inherit_from_id: instance_integration.id) }
      let(:created_integration) { Integration.find_by(group: subgroup) }
      let(:batch) { Group.where(id: subgroup.id) }
      let(:association) { 'group' }
      let(:inherit_from_id) { instance_integration.id }

      it_behaves_like 'creates integration successfully'

      it 'sets group_id in data_fields' do
        execute_service

        expect(created_integration.data_fields.group_id).to eq(subgroup.id)
        expect(created_integration.data_fields.project_id).to be_nil
        expect(created_integration.data_fields.organization_id).to be_nil
      end

      context 'with different foreign key of data_fields' do
        let(:integration) do
          create(:zentao_integration, :group, group: group, inherit_from_id: instance_integration.id)
        end

        it_behaves_like 'creates integration successfully'
      end

      it_behaves_like 'creates GitLab for Slack app data successfully' do
        let(:integration) { group_slack_integration }
        let(:expected_alias) { subgroup.full_path }

        it 'sets the group ID on the newly created slack integration' do
          execute_service

          expect(created_integration.group_id).to eq(subgroup.id)
          expect(created_integration.project_id).to be_nil
          expect(created_integration.organization_id).to be_nil
        end
      end
    end

    context 'when there are multiple integrations to create' do
      let!(:groups) { create_list(:group, 5, parent: group) }
      let!(:projects) { create_list(:project, 5, group: group) }
      let!(:integration) { create(:jira_integration, :group, group: group, inherit_from_id: instance_integration.id) }

      it 'sets correct foreign key to propagated integration data_fields' do
        described_class.new(integration, Project.where(id: projects.map(&:id)), 'project').execute
        described_class.new(integration, Group.where(id: groups.map(&:id)), 'group').execute

        groups.each do |subgroup|
          integration = Integration.find_by(group: subgroup)

          expect(integration.data_fields.group_id).to eq(integration.group_id)
          expect(integration.data_fields.project_id).to eq(integration.project_id)
          expect(integration.data_fields.organization_id).to eq(integration.organization_id)
        end

        projects.each do |project|
          integration = Integration.find_by(project: project)

          expect(integration.data_fields.group_id).to eq(integration.group_id)
          expect(integration.data_fields.project_id).to eq(integration.project_id)
          expect(integration.data_fields.organization_id).to eq(integration.organization_id)
        end
      end
    end
  end
end
