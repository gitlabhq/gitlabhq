# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateJiraTrackerDataDeploymentTypeBasedOnUrl do
  let(:integrations_table) { table(:integrations) }
  let(:service_jira_cloud) { integrations_table.create!(id: 1, type_new: 'JiraService') }
  let(:service_jira_server) { integrations_table.create!(id: 2, type_new: 'JiraService') }
  let(:service_jira_unknown) { integrations_table.create!(id: 3, type_new: 'JiraService') }

  let(:table_name) { :jira_tracker_data }
  let(:batch_column) { :id }
  let(:sub_batch_size) { 1 }
  let(:pause_ms) { 0 }
  let(:migration) do
    described_class.new(
      start_id: 1, end_id: 10,
      batch_table: table_name, batch_column: batch_column,
      sub_batch_size: sub_batch_size, pause_ms: pause_ms,
      connection: ApplicationRecord.connection
    )
  end

  subject(:perform_migration) do
    migration.perform
  end

  before do
    jira_tracker_data = Class.new(ApplicationRecord) do
      self.table_name = 'jira_tracker_data'

      def self.encryption_options
        {
          key: Settings.attr_encrypted_db_key_base_32,
          encode: true,
          mode: :per_attribute_iv,
          algorithm: 'aes-256-gcm'
        }
      end

      attr_encrypted :url, encryption_options
      attr_encrypted :api_url, encryption_options
      attr_encrypted :username, encryption_options
      attr_encrypted :password, encryption_options
    end

    stub_const('JiraTrackerData', jira_tracker_data)

    stub_const('UNKNOWN', 0)
    stub_const('SERVER', 1)
    stub_const('CLOUD', 2)
  end

  let!(:tracker_data_cloud) { JiraTrackerData.create!(id: 1, integration_id: service_jira_cloud.id, url: "https://test-domain.atlassian.net", deployment_type: UNKNOWN) }
  let!(:tracker_data_server) { JiraTrackerData.create!(id: 2, integration_id: service_jira_server.id, url: "http://totally-not-jira-server.company.org", deployment_type: UNKNOWN) }
  let!(:tracker_data_unknown) { JiraTrackerData.create!(id: 3, integration_id: service_jira_unknown.id, url: "", deployment_type: UNKNOWN) }

  it "changes unknown deployment_types based on URL" do
    expect(JiraTrackerData.pluck(:deployment_type)).to match_array([UNKNOWN, UNKNOWN, UNKNOWN])

    perform_migration

    expect(JiraTrackerData.order(:id).pluck(:deployment_type)).to match_array([CLOUD, SERVER, UNKNOWN])
  end
end
