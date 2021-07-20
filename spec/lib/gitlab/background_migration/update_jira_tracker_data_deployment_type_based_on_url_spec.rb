# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateJiraTrackerDataDeploymentTypeBasedOnUrl, schema: 20210421163509 do
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
  end

  let!(:tracker_data_cloud) { JiraTrackerData.create!(id: 1, service_id: service_jira_cloud.id, url: "https://test-domain.atlassian.net", deployment_type: 0) }
  let!(:tracker_data_server) { JiraTrackerData.create!(id: 2, service_id: service_jira_server.id, url: "http://totally-not-jira-server.company.org", deployment_type: 0) }

  subject { described_class.new.perform(tracker_data_cloud.id, tracker_data_server.id) }

  it "changes unknown deployment_types based on URL" do
    expect(JiraTrackerData.pluck(:deployment_type)).to eq([0, 0])

    subject

    expect(JiraTrackerData.pluck(:deployment_type)).to eq([2, 1])
  end
end
