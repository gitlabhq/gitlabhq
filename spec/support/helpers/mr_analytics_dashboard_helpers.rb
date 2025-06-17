# frozen_string_literal: true

module MrAnalyticsDashboardHelpers
  def visit_mr_analytics_dashboard(project)
    visit project_analytics_dashboards_path(project)

    within_testid('dashboards-list') do
      click_link('Merge request analytics')
    end

    wait_for_requests
  end

  def visit_mr_analytics_dashboard_with_custom_date_range(project, start_date:, end_date:)
    params = {
      date_range_option: 'custom',
      start_date: start_date,
      end_date: end_date
    }.to_query

    visit "#{project_analytics_dashboards_path(project)}/merge_request_analytics?#{params}"

    wait_for_requests
  end
end
