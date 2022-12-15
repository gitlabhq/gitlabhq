# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateJiraTrackerDataDeploymentTypeBasedOnUrl, :migration, feature_category: :integrations do
  let(:integrations_table) { table(:integrations) }
  let(:service_jira_cloud) { integrations_table.create!(id: 1, type_new: 'JiraService') }
  let(:service_jira_server) { integrations_table.create!(id: 2, type_new: 'JiraService') }

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
    stub_const("#{described_class}::SUB_BATCH_SIZE", 1)
  end

  # rubocop:disable Layout/LineLength
  # rubocop:disable RSpec/ScatteredLet
  let!(:tracker_data_cloud) { JiraTrackerData.create!(id: 1, integration_id: service_jira_cloud.id, url: "https://test-domain.atlassian.net", deployment_type: 0) }
  let!(:tracker_data_server) { JiraTrackerData.create!(id: 2, integration_id: service_jira_server.id, url: "http://totally-not-jira-server.company.org", deployment_type: 0) }
  # rubocop:enable Layout/LineLength
  # rubocop:enable RSpec/ScatteredLet

  around do |example|
    freeze_time { Sidekiq::Testing.fake! { example.run } }
  end

  let(:migration) { described_class::MIGRATION } # rubocop:disable RSpec/ScatteredLet

  it 'schedules background migration' do
    migrate!

    expect(migration).to have_scheduled_batched_migration(
      table_name: :jira_tracker_data,
      column_name: :id,
      interval: described_class::DELAY_INTERVAL,
      gitlab_schema: :gitlab_main
    )
  end
end
