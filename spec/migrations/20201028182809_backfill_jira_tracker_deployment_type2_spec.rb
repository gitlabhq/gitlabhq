# frozen_string_literal: true

require 'spec_helper'
require_migration!('backfill_jira_tracker_deployment_type2')

RSpec.describe BackfillJiraTrackerDeploymentType2, :sidekiq, schema: 20201028182809 do
  let(:services) { table(:services) }
  let(:jira_tracker_data) { table(:jira_tracker_data) }
  let(:migration) { described_class.new }
  let(:batch_interval) { described_class::DELAY_INTERVAL }

  describe '#up' do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 2)

      active_service   = services.create!(type: 'JiraService', active: true)
      inactive_service = services.create!(type: 'JiraService', active: false)

      jira_tracker_data.create!(id: 1, service_id: active_service.id, deployment_type: 0)
      jira_tracker_data.create!(id: 2, service_id: active_service.id, deployment_type: 1)
      jira_tracker_data.create!(id: 3, service_id: inactive_service.id, deployment_type: 2)
      jira_tracker_data.create!(id: 4, service_id: inactive_service.id, deployment_type: 0)
      jira_tracker_data.create!(id: 5, service_id: active_service.id, deployment_type: 0)
    end

    it 'schedules BackfillJiraTrackerDeploymentType2 background jobs' do
      Sidekiq::Testing.fake! do
        freeze_time do
          migration.up

          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(batch_interval, 1, 4)
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(batch_interval * 2, 5, 5)
        end
      end
    end
  end
end
