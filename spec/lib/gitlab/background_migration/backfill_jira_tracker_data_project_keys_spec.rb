# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillJiraTrackerDataProjectKeys, feature_category: :integrations do
  let(:integrations_table) { table(:integrations) }
  let(:jira_tracker_data_table) { table(:jira_tracker_data) }
  let(:jira_integration) { integrations_table.create!(id: 1, type_new: 'JiraService') }
  let!(:integration1) { jira_tracker_data_table.create!(integration_id: jira_integration.id, project_key: nil) }
  let!(:integration2) { jira_tracker_data_table.create!(integration_id: jira_integration.id, project_key: '') }
  let!(:integration3) do
    jira_tracker_data_table.create!(integration_id: jira_integration.id, project_key: 'GTL', project_keys: ['GTL'])
  end

  let!(:integration4) do
    jira_tracker_data_table.create!(integration_id: jira_integration.id, project_key: 'GTL', project_keys: [])
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: integration1.id,
      end_id: integration4.id,
      batch_table: :jira_tracker_data,
      batch_column: :id,
      sub_batch_size: 4,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  it 'updates project_keys values only for integrations with project_key and without project_keys' do
    expect { perform_migration }.to not_change { integration1.reload.project_keys }
                              .and not_change { integration2.reload.project_keys }
                              .and not_change { integration3.reload.project_keys }
                              .and change { integration4.reload.project_keys }.to(['GTL'])
  end
end
