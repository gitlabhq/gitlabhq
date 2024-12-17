# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Propagation::BulkUpdateService, feature_category: :integrations do
  include JiraIntegrationHelpers

  before_all do
    stub_jira_integration_test
  end

  let(:excluded_attributes) do
    %w[
      id project_id group_id inherit_from_id instance template
      created_at updated_at encrypted_properties encrypted_properties_iv
    ]
  end

  let(:batch) do
    Integration
      .inherited_descendants_from_self_or_ancestors_from(subgroup_integration)
      .where(id: group_integration.id..integration.id)
  end

  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:group_integration) { create(:jira_integration, :group, group: group, url: 'http://group.jira.com') }
  let_it_be(:excluded_integration) { create(:jira_integration, :group, group: create(:group), url: 'http://another.jira.com', push_events: false) }
  let_it_be(:subgroup_integration) do
    create(:jira_integration, :group,
      group: subgroup,
      inherit_from_id: group_integration.id,
      url: 'http://subgroup.jira.com',
      push_events: true
    )
  end

  let_it_be(:integration) do
    create(:jira_integration,
      project: create(:project, group: subgroup),
      inherit_from_id: subgroup_integration.id,
      url: 'http://project.jira.com',
      push_events: false
    )
  end

  context 'with inherited integration' do
    it 'updates the integration', :aggregate_failures do
      described_class.new(subgroup_integration.reload, batch).execute

      expect(integration.reload.inherit_from_id).to eq(group_integration.id)
      expect(integration.reload.attributes.except(*excluded_attributes))
        .to eq(subgroup_integration.reload.attributes.except(*excluded_attributes))

      expect(excluded_integration.reload.inherit_from_id).not_to eq(group_integration.id)
      expect(excluded_integration.reload.attributes.except(*excluded_attributes))
        .not_to eq(subgroup_integration.attributes.except(*excluded_attributes))
    end

    it 'does not change the created_at timestamp' do
      subgroup_integration.update_column(:created_at, Time.utc(2022, 1, 1))

      expect do
        described_class.new(subgroup_integration, batch).execute
      end.not_to change { integration.reload.created_at }
    end

    it 'sets the updated_at timestamp to the current time', time_travel_to: Time.utc(2022, 1, 1) do
      expect do
        described_class.new(subgroup_integration, batch).execute
      end.to change { integration.reload.updated_at }.to(Time.current)
    end

    context 'with integration with data fields' do
      let(:excluded_attributes) do
        %w[id integration_id created_at updated_at encrypted_properties encrypted_properties_iv]
      end

      it 'updates the data fields from the integration', :aggregate_failures do
        described_class.new(subgroup_integration, batch).execute

        expect(integration.reload.data_fields.attributes.except(*excluded_attributes))
          .to eq(subgroup_integration.reload.data_fields.attributes.except(*excluded_attributes))

        expect(integration.data_fields.attributes.except(*excluded_attributes))
          .not_to eq(excluded_integration.data_fields.attributes.except(*excluded_attributes))
      end

      it 'does not change the created_at timestamp' do
        subgroup_integration.data_fields.update_column(:created_at, Time.utc(2022, 1, 2))

        expect do
          described_class.new(subgroup_integration, batch).execute
        end.not_to change { integration.data_fields.reload.created_at }
      end

      it 'sets the updated_at timestamp to the current time', time_travel_to: Time.utc(2022, 1, 1) do
        expect do
          described_class.new(subgroup_integration, batch).execute
        end.to change { integration.data_fields.reload.updated_at }.to(Time.current)
      end
    end
  end

  it 'works with batch as an ActiveRecord::Relation' do
    expect do
      described_class.new(group_integration, Integration.where(id: integration.id)).execute
    end.to change { integration.reload.url }.to(group_integration.url)
  end

  it 'works with batch as an array of ActiveRecord objects' do
    expect do
      described_class.new(group_integration, [integration]).execute
    end.to change { integration.reload.url }.to(group_integration.url)
  end

  context 'with different foreign key of data_fields' do
    let(:integration) { create(:zentao_integration, project: create(:project, group: group)) }
    let(:group_integration) do
      create(:zentao_integration, :group,
        group: group,
        url: 'https://group.zentao.net',
        api_token: 'GROUP_TOKEN',
        zentao_product_xid: '1'
      )
    end

    it 'works with batch as an array of ActiveRecord objects' do
      expect do
        described_class.new(group_integration, [integration]).execute
      end.to change { integration.reload.url }.to(group_integration.url)
    end
  end

  context 'with a GitLab for Slack app integration' do
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project) { create(:project, group: subgroup) }

    let_it_be(:group_integration) do
      create(:gitlab_slack_application_integration, :group,
        group: group,
        slack_integration: build(:slack_integration,
          team_id: 'group_integration_team_id',
          team_name: 'group_integration_team_name',
          alias: 'group_alias',
          bot_access_token: 'group_integration_token',
          authorized_scope_names: %w[group_scope]
        )
      )
    end

    let_it_be(:subgroup_integration) do
      create(:gitlab_slack_application_integration, :group,
        group: subgroup,
        inherit_from_id: group_integration.id,
        slack_integration: build(:slack_integration,
          team_id: 'subgroup_integration_team_id',
          team_name: 'subgroup_integration_team_name',
          alias: 'subgroup_alias',
          bot_access_token: 'subgroup_integration_token',
          authorized_scope_names: %w[subgroup_scope]
        )
      )
    end

    let_it_be(:integration) do
      create(:gitlab_slack_application_integration,
        project: project,
        inherit_from_id: subgroup_integration.id,
        slack_integration: build(:slack_integration,
          alias: 'project_alias',
          authorized_scope_names: %w[project_scope]
        )
      )
    end

    let_it_be(:excluded_integration) do
      create(:gitlab_slack_application_integration,
        slack_integration: build(:slack_integration,
          team_id: 'excluded_team_id',
          alias: 'excluded_alias',
          authorized_scope_names: %w[excluded_scope]
        )
      )
    end

    let(:group_slack_integration) { group_integration.slack_integration }

    let(:batch) { Integration.id_in([subgroup_integration, integration]) }

    subject(:execute_service) do
      described_class.new(group_integration, batch).execute
    end

    it 'updates the SlackIntegration records and scopes, but not aliases' do
      execute_service

      expect(subgroup_integration.reload.slack_integration).to have_attributes(
        team_id: group_slack_integration.team_id,
        team_name: group_slack_integration.team_name,
        alias: 'subgroup_alias',
        user_id: group_slack_integration.user_id,
        bot_user_id: group_slack_integration.bot_user_id,
        bot_access_token: group_slack_integration.bot_access_token,
        created_at: be_present,
        updated_at: be_present,
        authorized_scope_names: group_slack_integration.authorized_scope_names
      )

      expect(integration.reload.slack_integration).to have_attributes(
        team_id: group_slack_integration.team_id,
        team_name: group_slack_integration.team_name,
        alias: 'project_alias',
        user_id: group_slack_integration.user_id,
        bot_user_id: group_slack_integration.bot_user_id,
        bot_access_token: group_slack_integration.bot_access_token,
        created_at: be_present,
        updated_at: be_present,
        authorized_scope_names: group_slack_integration.authorized_scope_names
      )

      expect(excluded_integration.reload.slack_integration).to have_attributes(
        team_id: 'excluded_team_id',
        alias: 'excluded_alias',
        authorized_scope_names: %w[excluded_scope]
      )
    end

    context 'when integration is disabled' do
      before do
        group_integration.update!(active: false)
      end

      it 'deletes associated SlackIntegration records' do
        expect { execute_service }.to change { SlackIntegration.count }.by(-2)
        expect(integration.reload.slack_integration).to be_nil
        expect(subgroup_integration.reload.slack_integration).to be_nil
        expect(excluded_integration.reload.slack_integration).to be_kind_of(SlackIntegration)
      end

      it 'deletes associated IntegrationApiScope records' do
        expect { execute_service }
          .to change { Integrations::SlackWorkspace::IntegrationApiScope.count }
          .by(-2)

        ids = Integrations::SlackWorkspace::IntegrationApiScope.pluck(:slack_integration_id)

        expect(ids).to contain_exactly(
          group_integration.slack_integration.id,
          excluded_integration.slack_integration.id
        )
      end
    end

    it 'avoids N+1 database queries' do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { execute_service }

      project_2 = create(:project, group: subgroup)
      project_2_integration = create(:gitlab_slack_application_integration,
        project: project_2,
        inherit_from_id: subgroup_integration.id,
        slack_integration: build(:slack_integration,
          alias: 'project_2_alias',
          authorized_scope_names: %w[project_2_scope]
        )
      )

      batch = Integration.id_in([subgroup_integration, integration, project_2_integration])

      expect do
        described_class.new(group_integration, batch).execute
      end.to issue_same_number_of_queries_as(control)
      expect(project_2_integration.reload.slack_integration).to have_attributes(
        team_id: group_slack_integration.team_id,
        authorized_scope_names: group_slack_integration.authorized_scope_names
      )
    end
  end
end
