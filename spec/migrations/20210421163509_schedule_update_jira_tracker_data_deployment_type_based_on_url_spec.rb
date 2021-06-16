# frozen_string_literal: true

require 'spec_helper'
require_migration!('schedule_update_jira_tracker_data_deployment_type_based_on_url')

RSpec.describe ScheduleUpdateJiraTrackerDataDeploymentTypeBasedOnUrl, :migration do
  let(:services_table) { table(:services) }
  let(:service_jira_cloud) { services_table.create!(id: 1, type: 'JiraService') }
  let(:service_jira_server) { services_table.create!(id: 2, type: 'JiraService') }

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
    stub_const("#{described_class}::BATCH_SIZE", 1)
  end

  let!(:tracker_data_cloud) { JiraTrackerData.create!(id: 1, service_id: service_jira_cloud.id, url: "https://test-domain.atlassian.net", deployment_type: 0) }
  let!(:tracker_data_server) { JiraTrackerData.create!(id: 2, service_id: service_jira_server.id, url: "http://totally-not-jira-server.company.org", deployment_type: 0) }

  around do |example|
    freeze_time { Sidekiq::Testing.fake! { example.run } }
  end

  it 'schedules background migration' do
    migrate!

    expect(BackgroundMigrationWorker.jobs.size).to eq(2)
    expect(described_class::MIGRATION).to be_scheduled_migration(tracker_data_cloud.id, tracker_data_cloud.id)
    expect(described_class::MIGRATION).to be_scheduled_migration(tracker_data_server.id, tracker_data_server.id)
  end
end
