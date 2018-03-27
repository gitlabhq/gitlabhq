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

      gcp_cluster = create(:cluster, :provided_by_gcp)
      create(:cluster, :provided_by_user)
      create(:cluster, :provided_by_user, :disabled)
      create(:clusters_applications_helm, :installed, cluster: gcp_cluster)
      create(:clusters_applications_ingress, :installed, cluster: gcp_cluster)
      create(:clusters_applications_prometheus, :installed, cluster: gcp_cluster)
      create(:clusters_applications_runner, :installed, cluster: gcp_cluster)
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
        signup
        ldap
        gravatar
        omniauth
        reply_by_email
        container_registry
        gitlab_pages
        gitlab_shared_runners
        git
        database
        avg_cycle_analytics
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
        ci_pipeline_config_auto_devops
        ci_pipeline_config_repository
        ci_runners
        ci_triggers
        ci_pipeline_schedules
        auto_devops_enabled
        auto_devops_disabled
        deploy_keys
        deployments
        environments
        clusters
        clusters_enabled
        clusters_disabled
        clusters_platforms_gke
        clusters_platforms_user
        clusters_applications_helm
        clusters_applications_ingress
        clusters_applications_prometheus
        clusters_applications_runner
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

      expect(count_data[:clusters_enabled]).to eq(6)
      expect(count_data[:clusters_disabled]).to eq(1)
      expect(count_data[:clusters_platforms_gke]).to eq(1)
      expect(count_data[:clusters_platforms_user]).to eq(1)
      expect(count_data[:clusters_applications_helm]).to eq(1)
      expect(count_data[:clusters_applications_ingress]).to eq(1)
      expect(count_data[:clusters_applications_prometheus]).to eq(1)
      expect(count_data[:clusters_applications_runner]).to eq(1)
    end
  end

  describe '#features_usage_data_ce' do
    subject { described_class.features_usage_data_ce }

    it 'gathers feature usage data' do
      expect(subject[:signup]).to eq(Gitlab::CurrentSettings.allow_signup?)
      expect(subject[:ldap]).to eq(Gitlab.config.ldap.enabled)
      expect(subject[:gravatar]).to eq(Gitlab::CurrentSettings.gravatar_enabled?)
      expect(subject[:omniauth]).to eq(Gitlab.config.omniauth.enabled)
      expect(subject[:reply_by_email]).to eq(Gitlab::IncomingEmail.enabled?)
      expect(subject[:container_registry]).to eq(Gitlab.config.registry.enabled)
      expect(subject[:gitlab_shared_runners]).to eq(Gitlab.config.gitlab_ci.shared_runners_enabled)
    end
  end

  describe '#components_usage_data' do
    subject { described_class.components_usage_data }

    it 'gathers components usage data' do
      expect(subject[:gitlab_pages][:enabled]).to eq(Gitlab.config.pages.enabled)
      expect(subject[:gitlab_pages][:version]).to eq(Gitlab::Pages::VERSION)
      expect(subject[:git][:version]).to eq(Gitlab::Git.version)
      expect(subject[:database][:adapter]).to eq(Gitlab::Database.adapter_name)
      expect(subject[:database][:version]).to eq(Gitlab::Database.version)
    end
  end

  describe '#license_usage_data' do
    subject { described_class.license_usage_data }

    it "gathers license data" do
      expect(subject[:uuid]).to eq(Gitlab::CurrentSettings.uuid)
      expect(subject[:version]).to eq(Gitlab::VERSION)
      expect(subject[:active_user_count]).to eq(User.active.count)
      expect(subject[:recorded_at]).to be_a(Time)
    end
  end
end
