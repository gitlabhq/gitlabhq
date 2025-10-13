# frozen_string_literal: true

RSpec.shared_examples 'renders usage overview metrics' do
  let(:usage_overview) { find_by_testid('panel-usage-overview') }

  it 'renders the metrics panel' do
    expect(usage_overview).to be_visible
    expect(usage_overview).to have_content format(_("Usage overview for the %{title}"), title: panel_title)
  end

  it 'renders each of the available metrics with the correct values' do
    within usage_overview do
      usage_overview_metrics.each do |id, name, value|
        stat = find_by_testid("usage-overview-metric-#{id}")
        expect(stat).to be_visible
        expect(stat).to have_content name
        expect(stat).to have_content value
      end
    end
  end
end

RSpec.shared_examples 'renders usage overview metrics with zero values' do
  it_behaves_like 'renders usage overview metrics'
end

RSpec.shared_examples 'renders usage overview metrics with empty values' do
  it_behaves_like 'renders usage overview metrics'
end

RSpec.shared_examples 'does not render usage overview metrics' do
  let(:usage_overview_testid) { "[data-testid='panel-usage-overview']" }

  it 'does not render the usage overview panel' do
    expect(page).not_to have_selector usage_overview_testid
  end
end

RSpec.shared_examples 'does not render usage overview background aggregation not enabled alert' do
  let(:vsd_background_aggregation_disabled_alert) { "[data-testid='vsd-background-aggregation-disabled-warning']" }

  it 'does not render background aggregation not enabled alert' do
    expect(page).not_to have_selector vsd_background_aggregation_disabled_alert
  end
end

RSpec.shared_examples 'renders metrics comparison tables' do
  let(:lifecycle_metrics_table) { find_by_testid('panel-vsd-lifecycle-metrics-table') }
  let(:dora_metrics_table) { find_by_testid('panel-vsd-dora-metrics-table') }
  let(:security_metrics_table) { find_by_testid('panel-vsd-security-metrics-table') }

  # Ideally we should be able to validate the rendered table values based on the mocked data,
  # but doing so has proven to be unreliable to this point. We've noticed recurring test
  # flake due to minor variations in the table values.

  # To ensure a consistent result, we've switched to using regex to validate the row content based
  # on metric unit type. This allows us to validate that the table structure is being rendered
  # correctly, by sacrificing the validation of the table values. Moving forward we should look
  # for a solution that allows us to validate both the table structure and values consistently.

  # Integer, or '-' for blank data
  # ex. 3 - 3 1 2 5
  let(:table_row_count_values) { %r{((- )|(\d+ )){6}} }

  # Number with ' d' suffix, or '-' for blank data
  # ex. 3.0 d 3.0 d - 4.0 d - 2.0 d
  let(:table_row_day_values) { %r{((- )|(\d+\.\d+ d )){6}} }

  # Number with '/d' suffix
  # ex. 0.0/d 0.0/d 0.26/d 0.31/d 0.16/d 0.0/d
  let(:table_row_per_day_values) { %r{(\d+\.\d+/d ){6}} }

  # Number with '%' suffix
  # ex. 0.0% 0.0% 12.5% 30.0% 40.0% 0.0%
  let(:table_row_percent_values) { %r{(\d+\.\d% ){6}} }

  # A formatted percentage like '40.5%', or 'n/a' for insufficient data
  let(:table_row_calculated_change) { %r{(n/a)|(\d+\.\d%)$} }

  def expect_row_content(id, name, values)
    row = find_by_testid("ai-impact-metric-#{id}")

    expect(row).to be_visible
    expect(row).to have_content name
    expect(row).to have_content values
    expect(row).to have_content table_row_calculated_change
  end

  before do
    wait_for_all_requests
  end

  it 'renders the Lifecycle metrics table' do
    expect(lifecycle_metrics_table).to be_visible
    expect(lifecycle_metrics_table).to have_content format(_("Lifecycle metrics for the %{title}"), title: panel_title)
    [
      ['lead-time', _('Lead time'), table_row_day_values],
      ['cycle-time', _('Cycle time'), table_row_day_values],
      ['issues', _('Issues created'), table_row_count_values],
      ['issues-completed', _('Issues closed'), table_row_count_values],
      ['deploys', _('Deploys'), table_row_count_values],
      ['merge-request-throughput', _('Merge request throughput'), table_row_count_values],
      ['median-time-to-merge', _('Median time to merge'), table_row_day_values]
    ].each do |id, name, values|
      expect_row_content(id, name, values)
    end
  end

  it 'renders the DORA metrics table' do
    expect(dora_metrics_table).to be_visible
    expect(dora_metrics_table).to have_content format(_("DORA metrics for the %{title}"), title: panel_title)
    [
      ['lead-time-for-changes', _('Lead time for changes'), table_row_day_values],
      ['time-to-restore-service', _('Time to restore service'), table_row_day_values],
      ['deployment-frequency', _('Deployment frequency'), table_row_per_day_values],
      ['change-failure-rate', _('Change failure rate'), table_row_percent_values]
    ].each do |id, name, values|
      expect_row_content(id, name, values)
    end
  end

  it 'renders the Security metrics table' do
    expect(security_metrics_table).to be_visible
    expect(security_metrics_table).to have_content format(_("Security metrics for the %{title}"), title: panel_title)
    [
      ['vulnerability-critical', _('Critical vulnerabilities over time'), table_row_count_values],
      ['vulnerability-high', _('High vulnerabilities over time'), table_row_count_values]
    ].each do |id, name, values|
      expect_row_content(id, name, values)
    end
  end
end

RSpec.shared_examples 'renders dora performers score' do
  let(:dora_performers_score) { find_by_testid('panel-dora-performers-score') }
  let(:dora_performers_chart_title) { find_by_testid('dora-performers-score-chart-title') }

  it 'renders the dora performers score visualization' do
    expect(dora_performers_score).to be_visible

    expect(dora_performers_score).to have_content format(
      _("DORA performers score for the %{name} group (Last full calendar month)"),
      name: group.name
    )
    expect(dora_performers_chart_title).to have_content _("Total projects (3) with DORA metrics")
  end
end

RSpec.shared_examples 'VSD renders as an analytics dashboard' do
  let(:dashboard_list_item_testid) { "[data-testid='dashboard-list-item']" }
  let(:feedback_survey) { find_by_testid('vsd-feedback-survey') }
  let(:vsd_background_aggregation_disabled_alert) { find_by_testid('vsd-background-aggregation-disabled-warning') }

  it 'renders VSD page correctly' do
    expect(find_by_testid('gridstack-grid')).to be_visible
    expect(page).not_to have_selector(dashboard_list_item_testid)
    expect(page).to have_content _('Value Streams Dashboard')
    expect(feedback_survey).to be_visible
    expect(feedback_survey).to have_content _("To help us improve the Value Stream Management Dashboard, " \
                                              "please share feedback about your experience in this survey.")
    expect(vsd_background_aggregation_disabled_alert).to be_visible

    expect(vsd_background_aggregation_disabled_alert).to have_content _('Background aggregation not enabled')
    expect(vsd_background_aggregation_disabled_alert).to have_content _("To see usage overview, you must enable " \
    "background aggregation.")
  end
end

RSpec.shared_examples 'renders contributor count' do
  let(:contributor_count) { find_by_testid('ai-impact-metric-contributor-count') }

  it 'renders the contributor count metric' do
    expect(contributor_count).to be_visible
  end
end

RSpec.shared_examples 'does not render contributor count' do
  let(:contributor_count_testid) { "[data-testid='ai-impact-metric-contributor-count']" }

  it 'does not render the contributor count metric' do
    expect(page).not_to have_selector contributor_count_testid
  end
end

RSpec.shared_examples 'has value streams dashboard link' do
  it 'renders the value streams dashboard link' do
    dashboard_items = page.all(dashboard_list_item_testid)

    vsd_dashboard = dashboard_items[0]

    expect(vsd_dashboard).to have_content _('Value Streams Dashboard')
    expect(vsd_dashboard).to have_selector dashboard_by_gitlab_testid
  end
end

RSpec.shared_examples 'renders unlicensed DORA performers score visualization' do
  let(:dora_performers_score) { find_by_testid('panel-dora-performers-score') }

  it 'renders the dora performers score visualization with a missing license message' do
    expect(dora_performers_score).to be_visible
    expect(dora_performers_score).to have_text "This feature requires an Ultimate plan Learn more."
  end
end

RSpec.shared_examples 'renders unlicensed DORA projects comparison visualization' do
  let(:dora_projects_comparison) { find_by_testid('panel-dora-projects-comparison') }

  it 'renders the DORA projects comparison with a missing license message' do
    expect(dora_projects_comparison).to be_visible
    expect(dora_projects_comparison).to have_text "This feature requires an Ultimate plan Learn more."
  end
end

RSpec.shared_examples 'renders unlicensed DORA metrics table visualization' do
  let(:dora_metrics_table) { find_by_testid('panel-vsd-dora-metrics-table') }

  it 'renders the DORA metrics table with a missing license message' do
    expect(dora_metrics_table).to be_visible
    expect(dora_metrics_table).to have_text "This feature requires an Ultimate plan Learn more."
  end
end

RSpec.shared_examples 'renders unlicensed security metrics visualization' do
  let(:security_metrics_table) { find_by_testid('panel-vsd-security-metrics-table') }

  it 'renders the security metrics visualization with a missing license message' do
    expect(security_metrics_table).to be_visible
    expect(security_metrics_table).to have_text "This feature requires an Ultimate plan Learn more."
  end
end

RSpec.shared_examples 'renders licensed VSD for a reporter' do
  let(:lifecycle_metrics_table) { find_by_testid('panel-vsd-lifecycle-metrics-table') }
  let(:security_metrics_table) { find_by_testid('panel-vsd-security-metrics-table') }
  let(:dora_metrics_table) { find_by_testid('panel-vsd-dora-metrics-table') }

  it 'renders the available visualizations' do
    [lifecycle_metrics_table, dora_metrics_table].each do |table|
      expect(table).to be_visible
      expect(table).not_to have_text "This feature requires an Ultimate plan Learn more."
    end

    expect(security_metrics_table).to be_visible
    expect(security_metrics_table).to have_text "You have insufficient permissions to view this panel."
  end
end
