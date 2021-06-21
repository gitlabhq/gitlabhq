# frozen_string_literal: true

require 'spec_helper'
require_migration!('reschedule_migrate_issue_trackers_data')

RSpec.describe RescheduleMigrateIssueTrackersData do
  let(:services) { table(:services) }
  let(:migration_class) { Gitlab::BackgroundMigration::MigrateIssueTrackersSensitiveData }
  let(:migration_name)  { migration_class.to_s.demodulize }

  let(:properties) do
    {
      'url' => 'http://example.com'
    }
  end

  let!(:jira_integration) do
    services.create!(id: 10, type: 'JiraService', properties: properties, category: 'issue_tracker')
  end

  let!(:jira_integration_nil) do
    services.create!(id: 11, type: 'JiraService', properties: nil, category: 'issue_tracker')
  end

  let!(:bugzilla_integration) do
    services.create!(id: 12, type: 'BugzillaService', properties: properties, category: 'issue_tracker')
  end

  let!(:youtrack_integration) do
    services.create!(id: 13, type: 'YoutrackService', properties: properties, category: 'issue_tracker')
  end

  let!(:youtrack_integration_empty) do
    services.create!(id: 14, type: 'YoutrackService', properties: '', category: 'issue_tracker')
  end

  let!(:gitlab_service) do
    services.create!(id: 15, type: 'GitlabIssueTrackerService', properties: properties, category: 'issue_tracker')
  end

  let!(:gitlab_service_empty) do
    services.create!(id: 16, type: 'GitlabIssueTrackerService', properties: {}, category: 'issue_tracker')
  end

  let!(:other_service) do
    services.create!(id: 17, type: 'OtherService', properties: properties, category: 'other_category')
  end

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)
  end

  describe "#up" do
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

  describe "#down" do
    let(:issue_tracker_data) { table(:issue_tracker_data) }
    let(:jira_tracker_data) { table(:jira_tracker_data) }

    let!(:valid_issue_tracker_data) do
      issue_tracker_data.create!(
        service_id: bugzilla_integration.id,
        encrypted_issues_url: 'http://url.com',
        encrypted_issues_url_iv: 'somevalue'
      )
    end

    let!(:invalid_issue_tracker_data) do
      issue_tracker_data.create!(
        service_id: bugzilla_integration.id,
        encrypted_issues_url: 'http:url.com',
        encrypted_issues_url_iv: nil
      )
    end

    let!(:valid_jira_tracker_data) do
      jira_tracker_data.create!(
        service_id: bugzilla_integration.id,
        encrypted_url: 'http://url.com',
        encrypted_url_iv: 'somevalue'
      )
    end

    let!(:invalid_jira_tracker_data) do
      jira_tracker_data.create!(
        service_id: bugzilla_integration.id,
        encrypted_url: 'http://url.com',
        encrypted_url_iv: nil
      )
    end

    it 'removes the invalid jira tracker data' do
      expect { described_class.new.down }.to change { jira_tracker_data.count }.from(2).to(1)

      expect(jira_tracker_data.all).to eq([valid_jira_tracker_data])
    end

    it 'removes the invalid issue tracker data' do
      expect { described_class.new.down }.to change { issue_tracker_data.count }.from(2).to(1)

      expect(issue_tracker_data.all).to eq([valid_issue_tracker_data])
    end
  end
end
