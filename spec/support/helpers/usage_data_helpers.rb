# frozen_string_literal: true

module UsageDataHelpers
  COUNTS_KEYS = %i[
    assignee_lists
    ci_external_pipelines
    ci_pipeline_config_auto_devops
    ci_pipeline_config_repository
    ci_triggers
    ci_pipeline_schedules
    auto_devops_enabled
    auto_devops_disabled
    deploy_keys
    environments
    clusters
    clusters_enabled
    project_clusters_enabled
    group_clusters_enabled
    instance_clusters_enabled
    clusters_disabled
    project_clusters_disabled
    group_clusters_disabled
    instance_clusters_disabled
    clusters_platforms_eks
    clusters_platforms_gke
    clusters_platforms_user
    clusters_integrations_prometheus
    clusters_management_project
    in_review_folder
    groups
    issues
    issues_created_from_gitlab_error_tracking_ui
    issues_with_associated_zoom_link
    issues_using_zoom_quick_actions
    incident_issues
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
    projects_asana_active
    projects_jenkins_active
    projects_jira_active
    projects_slack_active
    projects_slack_slash_commands_active
    projects_custom_issue_tracker_active
    projects_mattermost_active
    projects_prometheus_active
    projects_with_repositories_enabled
    projects_with_error_tracking_enabled
    projects_with_enabled_alert_integrations
    projects_with_terraform_reports
    projects_with_terraform_states
    pages_domains
    protected_branches
    protected_branches_except_default
    releases
    remote_mirrors
    suggestions
    terraform_reports
    terraform_states
    todos
    uploads
    web_hooks
    user_preferences_user_gitpod_enabled
  ].freeze

  USAGE_DATA_KEYS = %i[
    counts
    recorded_at
    gitlab_pages
    git
    gitaly
    database
    object_store
    topology
  ].freeze

  def stub_usage_data_connections
    Gitlab::Database.database_base_models_with_gitlab_shared.each_value do |base_model|
      allow(base_model.connection).to receive(:transaction_open?).and_return(false)
    end

    allow(Gitlab::Prometheus::Internal).to receive(:prometheus_enabled?).and_return(false)
  end

  def stub_prometheus_queries
    stub_request(:get, %r{^https?://.*:9090/-/ready})
      .to_return(
        status: 200,
        body: [{}].to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    stub_request(:get, %r{^https?://.*:9090/api/v1/query\?query=.*})
      .to_return(
        status: 200,
        body: [{}].to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_database_flavor_check(flavor = nil)
    allow(ApplicationRecord.database).to receive(:flavor).and_return(flavor)
  end

  def clear_memoized_values(values)
    values.each { |v| described_class.clear_memoization(v) }
  end

  def stub_object_store_settings
    allow(Settings).to receive(:[]).with('artifacts')
      .and_return(
        { 'enabled' => true,
          'object_store' =>
         { 'enabled' => true,
           'remote_directory' => 'artifacts',
           'direct_upload' => true,
           'connection' =>
         { 'provider' => 'AWS', 'aws_access_key_id' => 'minio', 'aws_secret_access_key' => 'gdk-minio', 'region' => 'gdk', 'endpoint' => 'http://127.0.0.1:9000', 'path_style' => true },
           'proxy_download' => false } }
      )

    allow(Settings).to receive(:[]).with('external_diffs').and_return({ 'enabled' => false })

    allow(Settings).to receive(:[]).with('lfs')
      .and_return(
        { 'enabled' => true,
          'object_store' =>
         { 'enabled' => false,
           'remote_directory' => 'lfs-objects',
           'direct_upload' => true,
           'connection' =>
         { 'provider' => 'AWS', 'aws_access_key_id' => 'minio', 'aws_secret_access_key' => 'gdk-minio', 'region' => 'gdk', 'endpoint' => 'http://127.0.0.1:9000', 'path_style' => true },
           'proxy_download' => false } }
      )
    allow(Settings).to receive(:[]).with('uploads')
      .and_return(
        { 'object_store' =>
          { 'enabled' => false,
            'remote_directory' => 'uploads',
            'direct_upload' => true,
            'connection' =>
          { 'provider' => 'AWS', 'aws_access_key_id' => 'minio', 'aws_secret_access_key' => 'gdk-minio', 'region' => 'gdk', 'endpoint' => 'http://127.0.0.1:9000', 'path_style' => true },
            'proxy_download' => false } }
      )
    allow(Settings).to receive(:[]).with('packages')
      .and_return(
        { 'enabled' => true,
          'object_store' =>
         { 'enabled' => false,
           'remote_directory' => 'packages',
           'direct_upload' => false,
           'connection' =>
         { 'provider' => 'AWS', 'aws_access_key_id' => 'minio', 'aws_secret_access_key' => 'gdk-minio', 'region' => 'gdk', 'endpoint' => 'http://127.0.0.1:9000', 'path_style' => true },
           'proxy_download' => false } }
      )
  end

  def expect_prometheus_client_to(*receive_matchers)
    receive_matchers.each { |m| expect(prometheus_client).to m }
  end

  def for_defined_days_back(days: [31, 3])
    days.each do |n|
      travel_to(n.days.ago) do
        yield
      end
    end
  end

  def load_sample_metric_definition(filename: 'sample_metric.yml')
    load_metric_yaml(fixture_file("lib/generators/gitlab/usage_metric_definition_generator/#{filename}"))
  end

  def load_metric_yaml(data)
    ::Gitlab::Config::Loader::Yaml.new(data).load_raw!
  end
end
