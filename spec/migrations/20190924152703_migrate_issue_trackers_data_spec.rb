# frozen_string_literal: true

require 'spec_helper'
require_migration!('migrate_issue_trackers_data')

RSpec.describe MigrateIssueTrackersData do
  let(:services) { table(:services) }
  let(:migration_class) { Gitlab::BackgroundMigration::MigrateIssueTrackersSensitiveData }
  let(:migration_name)  { migration_class.to_s.demodulize }

  let(:properties) do
    {
      'url' => 'http://example.com'
    }
  end

  let!(:jira_integration) do
    services.create!(type: 'JiraService', properties: properties, category: 'issue_tracker')
  end

  let!(:jira_integration_nil) do
    services.create!(type: 'JiraService', properties: nil, category: 'issue_tracker')
  end

  let!(:bugzilla_integration) do
    services.create!(type: 'BugzillaService', properties: properties, category: 'issue_tracker')
  end

  let!(:youtrack_integration) do
    services.create!(type: 'YoutrackService', properties: properties, category: 'issue_tracker')
  end

  let!(:youtrack_integration_empty) do
    services.create!(type: 'YoutrackService', properties: '', category: 'issue_tracker')
  end

  let!(:gitlab_service) do
    services.create!(type: 'GitlabIssueTrackerService', properties: properties, category: 'issue_tracker')
  end

  let!(:gitlab_service_empty) do
    services.create!(type: 'GitlabIssueTrackerService', properties: {}, category: 'issue_tracker')
  end

  let!(:other_service) do
    services.create!(type: 'OtherService', properties: properties, category: 'other_category')
  end

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)
  end

  it 'schedules background migrations at correct time' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(migration_name).to be_scheduled_delayed_migration(3.minutes, jira_integration.id, bugzilla_integration.id)
        expect(migration_name).to be_scheduled_delayed_migration(6.minutes, youtrack_integration.id, gitlab_service.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
