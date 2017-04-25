require 'spec_helper'

describe Gitlab::UsageData do
  let!(:project) { create(:empty_project) }
  let!(:project2) { create(:empty_project) }
  let!(:board) { create(:board, project: project) }

  describe '#data' do
    subject { Gitlab::UsageData.data }

    it "gathers usage data" do
      expect(subject.keys).to match_array(%i(
        active_user_count
        counts
        recorded_at
        mattermost_enabled
        edition
        version
        uuid
      ))
    end

    it "gathers usage counts" do
      count_data = subject[:counts]

      expect(count_data[:boards]).to eq(1)
      expect(count_data[:projects]).to eq(2)

      expect(count_data.keys).to match_array(%i(
        boards
        ci_builds
        ci_pipelines
        ci_runners
        ci_triggers
        ci_pipeline_schedules
        deploy_keys
        deployments
        environments
        groups
        issues
        keys
        labels
        lfs_objects
        merge_requests
        milestones
        notes
        projects
        projects_prometheus_active
        pages_domains
        protected_branches
        releases
        services
        snippets
        todos
        uploads
        web_hooks
      ))
    end
  end

  describe '#license_usage_data' do
    subject { Gitlab::UsageData.license_usage_data }

    it "gathers license data" do
      expect(subject[:uuid]).to eq(current_application_settings.uuid)
      expect(subject[:version]).to eq(Gitlab::VERSION)
      expect(subject[:active_user_count]).to eq(User.active.count)
      expect(subject[:recorded_at]).to be_a(Time)
    end
  end
end
