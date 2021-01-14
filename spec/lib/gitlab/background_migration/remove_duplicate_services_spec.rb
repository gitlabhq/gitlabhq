# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveDuplicateServices, :migration, schema: 20201207165956 do
  let_it_be(:users) { table(:users) }
  let_it_be(:namespaces) { table(:namespaces) }
  let_it_be(:projects) { table(:projects) }
  let_it_be(:services) { table(:services) }

  let_it_be(:alerts_service_data) { table(:alerts_service_data) }
  let_it_be(:chat_names) { table(:chat_names) }
  let_it_be(:issue_tracker_data) { table(:issue_tracker_data) }
  let_it_be(:jira_tracker_data) { table(:jira_tracker_data) }
  let_it_be(:open_project_tracker_data) { table(:open_project_tracker_data) }
  let_it_be(:slack_integrations) { table(:slack_integrations) }
  let_it_be(:web_hooks) { table(:web_hooks) }

  let_it_be(:data_tables) do
    [alerts_service_data, chat_names, issue_tracker_data, jira_tracker_data, open_project_tracker_data, slack_integrations, web_hooks]
  end

  let!(:user) { users.create!(id: 1, projects_limit: 100) }
  let!(:namespace) { namespaces.create!(id: 1, name: 'group', path: 'group') }

  # project without duplicate services
  let!(:project1) { projects.create!(id: 1, namespace_id: namespace.id) }
  let!(:service1) { services.create!(id: 1, project_id: project1.id, type: 'AsanaService') }
  let!(:service2) { services.create!(id: 2, project_id: project1.id, type: 'JiraService') }
  let!(:service3) { services.create!(id: 3, project_id: project1.id, type: 'SlackService') }

  # project with duplicate services
  let!(:project2) { projects.create!(id: 2, namespace_id: namespace.id) }
  let!(:service4) { services.create!(id: 4, project_id: project2.id, type: 'AsanaService') }
  let!(:service5) { services.create!(id: 5, project_id: project2.id, type: 'JiraService') }
  let!(:service6) { services.create!(id: 6, project_id: project2.id, type: 'JiraService') }
  let!(:service7) { services.create!(id: 7, project_id: project2.id, type: 'SlackService') }
  let!(:service8) { services.create!(id: 8, project_id: project2.id, type: 'SlackService') }
  let!(:service9) { services.create!(id: 9, project_id: project2.id, type: 'SlackService') }

  # project with duplicate services and dependant records
  let!(:project3) { projects.create!(id: 3, namespace_id: namespace.id) }
  let!(:service10) { services.create!(id: 10, project_id: project3.id, type: 'AlertsService') }
  let!(:service11) { services.create!(id: 11, project_id: project3.id, type: 'AlertsService') }
  let!(:service12) { services.create!(id: 12, project_id: project3.id, type: 'SlashCommandsService') }
  let!(:service13) { services.create!(id: 13, project_id: project3.id, type: 'SlashCommandsService') }
  let!(:service14) { services.create!(id: 14, project_id: project3.id, type: 'IssueTrackerService') }
  let!(:service15) { services.create!(id: 15, project_id: project3.id, type: 'IssueTrackerService') }
  let!(:service16) { services.create!(id: 16, project_id: project3.id, type: 'JiraService') }
  let!(:service17) { services.create!(id: 17, project_id: project3.id, type: 'JiraService') }
  let!(:service18) { services.create!(id: 18, project_id: project3.id, type: 'OpenProjectService') }
  let!(:service19) { services.create!(id: 19, project_id: project3.id, type: 'OpenProjectService') }
  let!(:service20) { services.create!(id: 20, project_id: project3.id, type: 'SlackService') }
  let!(:service21) { services.create!(id: 21, project_id: project3.id, type: 'SlackService') }
  let!(:dependant_records) do
    alerts_service_data.create!(id: 1, service_id: service10.id)
    alerts_service_data.create!(id: 2, service_id: service11.id)
    chat_names.create!(id: 1, service_id: service12.id, user_id: user.id, team_id: 'team1', chat_id: 'chat1')
    chat_names.create!(id: 2, service_id: service13.id, user_id: user.id, team_id: 'team2', chat_id: 'chat2')
    issue_tracker_data.create!(id: 1, service_id: service14.id)
    issue_tracker_data.create!(id: 2, service_id: service15.id)
    jira_tracker_data.create!(id: 1, service_id: service16.id)
    jira_tracker_data.create!(id: 2, service_id: service17.id)
    open_project_tracker_data.create!(id: 1, service_id: service18.id)
    open_project_tracker_data.create!(id: 2, service_id: service19.id)
    slack_integrations.create!(id: 1, service_id: service20.id, user_id: user.id, team_id: 'team1', team_name: 'team1', alias: 'alias1')
    slack_integrations.create!(id: 2, service_id: service21.id, user_id: user.id, team_id: 'team2', team_name: 'team2', alias: 'alias2')
    web_hooks.create!(id: 1, service_id: service20.id)
    web_hooks.create!(id: 2, service_id: service21.id)
  end

  # project without services
  let!(:project4) { projects.create!(id: 4, namespace_id: namespace.id) }

  it 'removes duplicate services and dependant records' do
    # Determine which services we expect to keep
    expected_services = projects.pluck(:id).each_with_object({}) do |project_id, map|
      project_services = services.where(project_id: project_id)
      types = project_services.distinct.pluck(:type)

      map[project_id] = types.map { |type| project_services.where(type: type).take!.id }
    end

    expect do
      subject.perform(project2.id, project3.id)
    end.to change { services.count }.from(21).to(12)

    services1 = services.where(project_id: project1.id)
    expect(services1.count).to be(3)
    expect(services1.pluck(:type)).to contain_exactly('AsanaService', 'JiraService', 'SlackService')
    expect(services1.pluck(:id)).to contain_exactly(*expected_services[project1.id])

    services2 = services.where(project_id: project2.id)
    expect(services2.count).to be(3)
    expect(services2.pluck(:type)).to contain_exactly('AsanaService', 'JiraService', 'SlackService')
    expect(services2.pluck(:id)).to contain_exactly(*expected_services[project2.id])

    services3 = services.where(project_id: project3.id)
    expect(services3.count).to be(6)
    expect(services3.pluck(:type)).to contain_exactly('AlertsService', 'SlashCommandsService', 'IssueTrackerService', 'JiraService', 'OpenProjectService', 'SlackService')
    expect(services3.pluck(:id)).to contain_exactly(*expected_services[project3.id])

    kept_services = expected_services.values.flatten
    data_tables.each do |table|
      expect(table.count).to be(1)
      expect(kept_services).to include(table.pluck(:service_id).first)
    end
  end

  it 'does not delete services without duplicates' do
    expect do
      subject.perform(project1.id, project4.id)
    end.not_to change { services.count }
  end

  it 'only deletes duplicate services for the current batch' do
    expect do
      subject.perform(project2.id)
    end.to change { services.count }.by(-3)
  end
end
