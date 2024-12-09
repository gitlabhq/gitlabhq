# frozen_string_literal: true

module ValueStreamsDashboardHelpers
  def visit_group_analytics_dashboards_list(group)
    visit group_analytics_dashboards_path(group)
  end

  def visit_group_value_streams_dashboard(group, vsd_title = 'Value Streams Dashboard')
    visit group_analytics_dashboards_path(group)
    click_link(vsd_title)

    wait_for_requests
  end

  def visit_project_analytics_dashboards_list(project)
    visit project_analytics_dashboards_path(project)
  end

  def visit_project_value_streams_dashboard(project)
    visit project_analytics_dashboards_path(project)
    click_link "Value Streams Dashboard"

    wait_for_requests
  end

  def dashboard_by_gitlab_testid
    "[data-testid='dashboard-by-gitlab']"
  end

  def dashboard_list_item_testid
    "[data-testid='dashboard-list-item']"
  end

  def create_custom_yaml_config(user, pointer_project, yaml_fixture_path)
    repository_file_path = '.gitlab/analytics/dashboards/value_streams/value_streams.yaml'

    pointer_project.repository.create_file(
      user,
      repository_file_path,
      File.read(yaml_fixture_path),
      message: "commit #{repository_file_path}",
      branch_name: 'master'
    )
  end

  def create_mock_usage_overview_metrics(project)
    [
      [:groups, 5, project.group],
      [:projects, 10, project.group],
      [:direct_members, 100, project.group],
      [:issues, 1500, project.project_namespace],
      [:merge_requests, 1000, project.project_namespace],
      [:pipelines, 2000, project.project_namespace]
    ].each do |metric, count, namespace|
      create(
        :value_stream_dashboard_count,
        metric: metric,
        count: count,
        namespace: namespace,
        recorded_at: 1.week.ago
      )
    end
  end

  def expected_usage_overview_metrics(is_project: false)
    supported_project_usage_metrics = [
      ['issues', _('Issues'), '1,500'],
      ['merge_requests', _('Merge requests'), '1,000'],
      ['pipelines', _('Pipelines'), '2,000']
    ]

    if is_project
      supported_project_usage_metrics
    else
      [
        ['groups', _('Groups'), '5'],
        ['projects', _('Projects'), '10'],
        ['users', _('Users'), '100']
      ].concat(supported_project_usage_metrics)
    end
  end

  def expected_usage_overview_metrics_zero_values(is_project: false)
    supported_project_usage_metrics = [
      ['issues', _('Issues'), '0'],
      ['merge_requests', _('Merge requests'), '0'],
      ['pipelines', _('Pipelines'), '0']
    ]

    if is_project
      supported_project_usage_metrics
    else
      [
        ['groups', _('Groups'), '0'],
        ['projects', _('Projects'), '0'],
        ['users', _('Users'), '0']
      ].concat(supported_project_usage_metrics)
    end
  end

  def expected_usage_overview_metrics_empty_values(is_project: false)
    supported_project_usage_metrics = [
      ['issues', _('Issues'), '-'],
      ['merge_requests', _('Merge requests'), '-'],
      ['pipelines', _('Pipelines'), '-']
    ]

    if is_project
      supported_project_usage_metrics
    else
      [
        ['groups', _('Groups'), '-'],
        ['projects', _('Projects'), '-'],
        ['users', _('Users'), '-']
      ].concat(supported_project_usage_metrics)
    end
  end

  def create_mock_dora_performers_score_metrics(group)
    [
      [nil, 'high', 'high', 'high'],
      %w[high low low medium],
      ['medium', 'low', 'medium', nil]
    ].each do |deployment_frequency, lead_time_for_changes, time_to_restore_service, change_failure_rate|
      create(
        :dora_performance_score,
        project: create(:project, group: group),
        date: 1.month.ago.beginning_of_month,
        deployment_frequency: deployment_frequency,
        lead_time_for_changes: lead_time_for_changes,
        time_to_restore_service: time_to_restore_service,
        change_failure_rate: change_failure_rate
      )
    end
  end

  def create_mock_dora_chart_metrics(environment)
    project = environment.project

    create_mock_dora_metrics(environment)
    create_mock_flow_metrics(project)
    create_mock_merge_request_metrics(project)
    create_mock_vulnerabilities_metrics('vulnerability_historical_statistic', { project: project })
    create_mock_vulnerabilities_metrics('vulnerability_namespace_historical_statistic',
      { namespace: project.namespace })
  end

  # On the 1st day of any month, the metrics table intentionally uses the previous month
  # in the `Current month` column. To handle that case, we need to shift
  # the generated test metric dates by 1 month.
  def n_months_ago(count)
    count += 1 if Date.today.day == 1
    count.months.ago
  end

  def create_mock_dora_metrics(environment)
    seconds_in_1_day = 60 * 60 * 24
    [
      [n_months_ago(1), 5, 1, 5, 2],
      [n_months_ago(2), 10, 3, 3, 3],
      [n_months_ago(3), 8, 5, 7, 1]
    ].each do |date, deploys, lead_time_for_changes, time_to_restore_service, incidents_count|
      create(
        :dora_daily_metrics,
        deployment_frequency: deploys,
        lead_time_for_changes_in_seconds: lead_time_for_changes * seconds_in_1_day,
        time_to_restore_service_in_seconds: time_to_restore_service * seconds_in_1_day,
        incidents_count: incidents_count,
        environment: environment,
        date: date
      )
    end
  end

  def create_mock_flow_metrics(project)
    [
      [n_months_ago(1).beginning_of_month + 2.days, 2, 2],
      [n_months_ago(2).beginning_of_month + 2.days, 4, 1],
      [n_months_ago(3).beginning_of_month + 2.days, 3, 3]
    ].each do |created_at, lead_time, count|
      count.times do
        create(
          :issue,
          project: project,
          created_at: created_at,
          closed_at: created_at + lead_time.days
        ).metrics.update!(first_mentioned_in_commit_at: created_at + 1.day)
      end
    end

    Analytics::CycleAnalytics::DataLoaderService.new(namespace: project.group, model: Issue).execute
  end

  def create_mock_merge_request_metrics(project)
    [
      [n_months_ago(1), 3],
      [n_months_ago(2), 1],
      [n_months_ago(3), 2]
    ].each do |merged_at, count|
      count.times do
        create(
          :merge_request,
          :skip_diff_creation,
          :merged,
          created_at: 1.year.ago,
          project: project
        ).metrics.update!(merged_at: merged_at)
      end
    end
  end

  def create_mock_vulnerabilities_metrics(table_name, record_identifier)
    [
      [n_months_ago(1).end_of_month, 3, 2],
      [n_months_ago(2).end_of_month, 5, 4],
      [n_months_ago(3).end_of_month, 2, 3]
    ].each do |date, critical, high|
      params = {
        date: date,
        high: high,
        critical: critical,
        total: critical + high
      }.merge(record_identifier)

      create(table_name.to_sym, params)
    end
  end
end
