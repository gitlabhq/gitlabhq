require 'spec_helper'

describe Gitlab::UsageData do
  let(:projects) { create_list(:project, 3) }
  let!(:board) { create(:board, project: projects[0]) }

  describe '#data' do
    before do
      create(:jira_service, project: projects[0])
      create(:jira_service, project: projects[1])
      create(:jira_cloud_service, project: projects[2])
      create(:prometheus_service, project: projects[1])
      create(:service, project: projects[0], type: 'SlackSlashCommandsService', active: true)
      create(:service, project: projects[1], type: 'SlackService', active: true)
      create(:service, project: projects[2], type: 'SlackService', active: true)
      create(:project_error_tracking_setting, project: projects[0])
      create(:project_error_tracking_setting, project: projects[1], enabled: false)

      gcp_cluster = create(:cluster, :provided_by_gcp)
      create(:cluster, :provided_by_user)
      create(:cluster, :provided_by_user, :disabled)
      create(:cluster, :group)
      create(:cluster, :group, :disabled)
      create(:cluster, :group, :disabled)
      create(:clusters_applications_helm, :installed, cluster: gcp_cluster)
      create(:clusters_applications_ingress, :installed, cluster: gcp_cluster)
      create(:clusters_applications_cert_managers, :installed, cluster: gcp_cluster)
      create(:clusters_applications_prometheus, :installed, cluster: gcp_cluster)
      create(:clusters_applications_runner, :installed, cluster: gcp_cluster)
      create(:clusters_applications_knative, :installed, cluster: gcp_cluster)

      ProjectFeature.first.update_attribute('repository_access_level', 0)
    end

    subject { described_class.data }

    it "gathers usage data" do
      expect(subject.keys).to include(*%i(
        active_user_count
        counts
        recorded_at
        edition
        version
        installation_type
        uuid
        hostname
        mattermost_enabled
        signup_enabled
        ldap_enabled
        gravatar_enabled
        omniauth_enabled
        reply_by_email_enabled
        container_registry_enabled
        gitlab_shared_runners_enabled
        gitlab_pages
        git
        database
        avg_cycle_analytics
        web_ide_commits
        influxdb_metrics_enabled
        prometheus_metrics_enabled
      ))
    end

    it "gathers usage counts" do
      expected_keys = %i(
        assignee_lists
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
        successful_deployments
        failed_deployments
        environments
        clusters
        clusters_enabled
        project_clusters_enabled
        group_clusters_enabled
        clusters_disabled
        project_clusters_disabled
        group_clusters_disabled
        clusters_platforms_gke
        clusters_platforms_user
        clusters_applications_helm
        clusters_applications_ingress
        clusters_applications_cert_managers
        clusters_applications_prometheus
        clusters_applications_runner
        clusters_applications_knative
        in_review_folder
        groups
        issues
        keys
        label_lists
        labels
        lfs_objects
        merge_requests
        milestone_lists
        milestones
        notes
        pool_repositories
        projects
        projects_imported_from_github
        projects_jira_active
        projects_jira_server_active
        projects_jira_cloud_active
        projects_slack_notifications_active
        projects_slack_slash_active
        projects_prometheus_active
        projects_with_repositories_enabled
        projects_with_error_tracking_enabled
        pages_domains
        protected_branches
        releases
        remote_mirrors
        snippets
        suggestions
        todos
        uploads
        web_hooks
        user_preferences
      )

      count_data = subject[:counts]

      expect(count_data[:boards]).to eq(1)
      expect(count_data[:projects]).to eq(3)
      expect(count_data.keys).to include(*expected_keys)
      expect(expected_keys - count_data.keys).to be_empty
    end

    it 'does not gather user preferences usage data when the feature is disabled' do
      stub_feature_flags(group_overview_security_dashboard: false)
      expect(subject[:counts].keys).not_to include(:user_preferences)
    end

    it 'gathers projects data correctly' do
      count_data = subject[:counts]

      expect(count_data[:projects]).to eq(3)
      expect(count_data[:projects_prometheus_active]).to eq(1)
      expect(count_data[:projects_jira_active]).to eq(3)
      expect(count_data[:projects_jira_server_active]).to eq(2)
      expect(count_data[:projects_jira_cloud_active]).to eq(1)
      expect(count_data[:projects_slack_notifications_active]).to eq(2)
      expect(count_data[:projects_slack_slash_active]).to eq(1)
      expect(count_data[:projects_with_repositories_enabled]).to eq(2)
      expect(count_data[:projects_with_error_tracking_enabled]).to eq(1)

      expect(count_data[:clusters_enabled]).to eq(7)
      expect(count_data[:project_clusters_enabled]).to eq(6)
      expect(count_data[:group_clusters_enabled]).to eq(1)
      expect(count_data[:clusters_disabled]).to eq(3)
      expect(count_data[:project_clusters_disabled]).to eq(1)
      expect(count_data[:group_clusters_disabled]).to eq(2)
      expect(count_data[:group_clusters_enabled]).to eq(1)
      expect(count_data[:clusters_platforms_gke]).to eq(1)
      expect(count_data[:clusters_platforms_user]).to eq(1)
      expect(count_data[:clusters_applications_helm]).to eq(1)
      expect(count_data[:clusters_applications_ingress]).to eq(1)
      expect(count_data[:clusters_applications_cert_managers]).to eq(1)
      expect(count_data[:clusters_applications_prometheus]).to eq(1)
      expect(count_data[:clusters_applications_runner]).to eq(1)
      expect(count_data[:clusters_applications_knative]).to eq(1)
    end

    it 'works when queries time out' do
      allow_any_instance_of(ActiveRecord::Relation)
        .to receive(:count).and_raise(ActiveRecord::StatementInvalid.new(''))

      expect { subject }.not_to raise_error
    end
  end

  describe '#features_usage_data_ce' do
    subject { described_class.features_usage_data_ce }

    it 'gathers feature usage data' do
      expect(subject[:mattermost_enabled]).to eq(Gitlab.config.mattermost.enabled)
      expect(subject[:signup_enabled]).to eq(Gitlab::CurrentSettings.allow_signup?)
      expect(subject[:ldap_enabled]).to eq(Gitlab.config.ldap.enabled)
      expect(subject[:gravatar_enabled]).to eq(Gitlab::CurrentSettings.gravatar_enabled?)
      expect(subject[:omniauth_enabled]).to eq(Gitlab::Auth.omniauth_enabled?)
      expect(subject[:reply_by_email_enabled]).to eq(Gitlab::IncomingEmail.enabled?)
      expect(subject[:container_registry_enabled]).to eq(Gitlab.config.registry.enabled)
      expect(subject[:gitlab_shared_runners_enabled]).to eq(Gitlab.config.gitlab_ci.shared_runners_enabled)
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
      expect(subject[:installation_type]).to eq('gitlab-development-kit')
      expect(subject[:active_user_count]).to eq(User.active.count)
      expect(subject[:recorded_at]).to be_a(Time)
    end
  end

  describe '#count' do
    let(:relation) { double(:relation) }

    it 'returns the count when counting succeeds' do
      allow(relation).to receive(:count).and_return(1)

      expect(described_class.count(relation)).to eq(1)
    end

    it 'returns the fallback value when counting fails' do
      allow(relation).to receive(:count).and_raise(ActiveRecord::StatementInvalid.new(''))

      expect(described_class.count(relation, fallback: 15)).to eq(15)
    end
  end

  describe '#approximate_counts' do
    it 'gets approximate counts for selected models' do
      create(:label)

      expect(Gitlab::Database::Count).to receive(:approximate_counts)
        .with(described_class::APPROXIMATE_COUNT_MODELS).once.and_call_original

      counts = described_class.approximate_counts.values

      expect(counts.count).to eq(described_class::APPROXIMATE_COUNT_MODELS.count)
      expect(counts.any? { |count| count < 0 }).to be_falsey
    end

    it 'returns default values if counts can not be retrieved' do
      described_class::APPROXIMATE_COUNT_MODELS.map do |model|
        model.name.underscore.pluralize.to_sym
      end

      expect(Gitlab::Database::Count).to receive(:approximate_counts)
        .and_return({})

      expect(described_class.approximate_counts.values.uniq).to eq([-1])
    end
  end
end
