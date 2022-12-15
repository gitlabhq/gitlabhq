# frozen_string_literal: true
require 'spec_helper'

require_migration!

RSpec.describe DeleteServiceTemplateRecords, feature_category: :integrations do
  let(:integrations) { table(:integrations) }
  let(:chat_names) { table(:chat_names) }
  let(:web_hooks) { table(:web_hooks) }
  let(:slack_integrations) { table(:slack_integrations) }
  let(:zentao_tracker_data) { table(:zentao_tracker_data) }
  let(:jira_tracker_data) { table(:jira_tracker_data) }
  let(:issue_tracker_data) { table(:issue_tracker_data) }

  before do
    template = integrations.create!(template: true)
    chat_names.create!(service_id: template.id, user_id: 1, team_id: 1, chat_id: 1)
    web_hooks.create!(service_id: template.id)
    slack_integrations.create!(service_id: template.id, team_id: 1, team_name: 'team', alias: 'alias', user_id: 1)
    zentao_tracker_data.create!(integration_id: template.id)
    jira_tracker_data.create!(service_id: template.id)
    issue_tracker_data.create!(service_id: template.id)

    integrations.create!(template: false)
  end

  it 'deletes template records and associated data' do
    expect { migrate! }
      .to change { integrations.where(template: true).count }.from(1).to(0)
      .and change { chat_names.count }.from(1).to(0)
      .and change { web_hooks.count }.from(1).to(0)
      .and change { slack_integrations.count }.from(1).to(0)
      .and change { zentao_tracker_data.count }.from(1).to(0)
      .and change { jira_tracker_data.count }.from(1).to(0)
      .and change { issue_tracker_data.count }.from(1).to(0)
  end

  it 'does not delete non template records' do
    expect { migrate! }
      .not_to change { integrations.where(template: false).count }
  end
end
