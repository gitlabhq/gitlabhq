# frozen_string_literal: true

module ValueStreamsDashboardHelpers
  def visit_group_analytics_dashboards_list(group)
    visit group_analytics_dashboards_path(group)
  end

  def visit_group_value_streams_dashboard(group)
    visit group_analytics_dashboards_path(group)
    click_link "Value Streams Dashboard"

    wait_for_requests
  end

  def expect_metric(metric)
    row = find_by_testid("dora-chart-metric-#{metric[:identifier]}")

    expect(row).to be_visible

    expect(row).to have_content metric[:name]
    expect(row).to have_content metric[:values].join(" ")
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
end
