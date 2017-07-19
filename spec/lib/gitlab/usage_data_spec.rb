require 'spec_helper'

describe Gitlab::UsageData do
  let(:projects) { create_list(:project, 3) }
  let!(:board) { create(:board, project: projects[0]) }

  describe '#data' do
    before do
      create(:jira_service, project: projects[0])
      create(:jira_service, project: projects[1])
      create(:prometheus_service, project: projects[1])
      create(:service, project: projects[0], type: 'SlackSlashCommandsService', active: true)
      create(:service, project: projects[1], type: 'SlackService', active: true)
      create(:service, project: projects[2], type: 'SlackService', active: true)
    end

    subject { described_class.data }

    it "gathers usage data" do
      expect(subject.keys).to match_array(%i(
        active_user_count
        counts
        recorded_at
        mattermost_enabled
        edition
        version
        uuid
        hostname
      ))
    end

    it "gathers usage counts" do
      count_data = subject[:counts]

      expect(count_data[:boards]).to eq(1)
      expect(count_data[:projects]).to eq(3)

      expect(count_data.keys).to match_array(%i(
        boards
        ci_builds
        ci_internal_pipelines
        ci_external_pipelines
        ci_runners
        ci_triggers
        ci_pipeline_schedules
        deploy_keys
        deployments
        environments
        in_review_folder
        groups
        issues
        keys
        labels
        lfs_objects
        merge_requests
        milestones
        notes
        projects
        projects_imported_from_github
        projects_jira_active
        projects_slack_notifications_active
        projects_slack_slash_active
        projects_prometheus_active
        pages_domains
        protected_branches
        releases
        snippets
        todos
        uploads
        web_hooks
      ))
    end

    it 'gathers projects data correctly' do
      count_data = subject[:counts]

      expect(count_data[:projects]).to eq(3)
      expect(count_data[:projects_prometheus_active]).to eq(1)
      expect(count_data[:projects_jira_active]).to eq(2)
      expect(count_data[:projects_slack_notifications_active]).to eq(2)
      expect(count_data[:projects_slack_slash_active]).to eq(1)
    end
  end

  describe '#license_usage_data' do
    subject { described_class.license_usage_data }

    it "gathers license data" do
      expect(subject[:uuid]).to eq(current_application_settings.uuid)
      expect(subject[:version]).to eq(Gitlab::VERSION)
      expect(subject[:active_user_count]).to eq(User.active.count)
      expect(subject[:recorded_at]).to be_a(Time)
    end
  end
end
