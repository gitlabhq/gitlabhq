# frozen_string_literal: true

module DoraMetricsDashboardHelpers
  def visit_group_dora_metrics_dashboard(group)
    visit group_analytics_dashboards_path(group)
    click_link('DORA metrics analytics')

    wait_for_requests
  end

  def visit_project_dora_metrics_dashboard(project)
    visit project_analytics_dashboards_path(project)
    click_link('DORA metrics analytics')

    wait_for_requests
  end
end
