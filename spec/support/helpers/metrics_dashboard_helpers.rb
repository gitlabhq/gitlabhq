# frozen_string_literal: true

module MetricsDashboardHelpers
  # @param dashboards [Hash<string, string>] - Should contain a hash where
  #     each key is the path to a dashboard in the repository and each value is
  #     the dashboard content.
  #     Ex: { '.gitlab/dashboards/dashboard1.yml' => fixture_file('lib/gitlab/metrics/dashboard/sample_dashboard.yml') }
  def project_with_dashboards(dashboards, project_params = {})
    create(:project, :custom_repo, **project_params, files: dashboards)
  end

  def project_with_dashboard(dashboard_path, dashboard_yml = nil, project_params = {})
    dashboard_yml ||= fixture_file('lib/gitlab/metrics/dashboard/sample_dashboard.yml')

    project_with_dashboards({ dashboard_path => dashboard_yml }, project_params)
  end

  def project_with_dashboard_namespace(dashboard_path, dashboard_yml = nil, project_params = {})
    project_with_dashboard(dashboard_path, dashboard_yml, project_params.reverse_merge(path: 'monitor-project'))
  end

  def delete_project_dashboard(project, user, dashboard_path)
    project.repository.delete_file(
      user,
      dashboard_path,
      branch_name: 'master',
      message: 'Delete dashboard'
    )

    project.repository.refresh_method_caches([:metrics_dashboard])
  end

  def load_sample_dashboard
    load_dashboard_yaml(fixture_file('lib/gitlab/metrics/dashboard/sample_dashboard.yml'))
  end

  def load_dashboard_yaml(data)
    ::Gitlab::Config::Loader::Yaml.new(data).load_raw!
  end

  def business_metric_title
    Enums::PrometheusMetric.group_details[:business][:group_title]
  end
end
