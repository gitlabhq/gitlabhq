# frozen_string_literal: true

RSpec.shared_examples 'renders usage overview metrics' do
  let(:usage_overview) { find_by_testid('panel-usage-overview') }

  it 'renders the metrics panel' do
    expect(usage_overview).to be_visible
    expect(usage_overview).to have_content format(_("Usage overview for %{name} group"), name: group.name)
  end

  it 'renders each of the available metrics' do
    usage_metrics = [_("Groups"), _("Projects"), _("Issues"), _("Merge requests"), _("Pipelines")]

    within usage_overview do
      metric_titles = all('[data-testid="title-text"]').collect(&:text)

      expect(metric_titles).to match_array usage_metrics
    end
  end
end

RSpec.shared_examples 'does not render usage overview metrics' do
  let(:usage_overview_testid) { "[data-testid='panel-usage-overview']" }

  it 'does not render the usage overview panel' do
    expect(page).not_to have_selector usage_overview_testid
  end
end

RSpec.shared_examples 'renders metrics comparison table' do
  let(:metric_table) { find_by_testid('panel-dora-chart') }

  available_metrics = [
    { name: "Deployment frequency", values: ["0.0/d"] * 3, identifier: 'deployment-frequency' },
    { name: "Lead time for changes", values: ["0.0 d"] * 3, identifier: 'lead-time-for-changes' },
    { name: "Time to restore service", values: ["0.0 d"] * 3, identifier: 'time-to-restore-service' },
    { name: "Change failure rate", values: ["0.0%"] * 3, identifier: 'change-failure-rate' },
    { name: "Lead time", values: ["-"] * 3, identifier: 'lead-time' },
    { name: "Cycle time", values: ["-"] * 3, identifier: 'cycle-time' },
    { name: "Issues created", values: ["-"] * 3, identifier: 'issues' },
    { name: "Issues closed", values: ["-"] * 3, identifier: 'issues-completed' },
    { name: "Deploys", values: ["-"] * 3, identifier: 'deploys' },
    { name: "Merge request throughput", values: ["-"] * 3, identifier: 'merge-request-throughput' },
    { name: "Critical vulnerabilities over time", values: ["-"] * 3, identifier: "vulnerability-critical" },
    { name: "High vulnerabilities over time", values: ["-"] * 3, identifier: 'vulnerability-high' }
  ]

  it 'renders the metrics comparison visualization' do
    expect(metric_table).to be_visible
    expect(metric_table).to have_content format(_("Metrics comparison for %{name} group"), name: group_name)
  end

  it "renders the available metrics" do
    wait_for_all_requests

    available_metrics.each do |metric|
      expect_metric(metric)
    end
  end
end

RSpec.shared_examples 'renders dora performers score' do
  let(:dora_performers_score) { find_by_testid('panel-dora-performers-score') }
  let(:dora_performers_chart_title) { find_by_testid('dora-performers-score-chart-title') }

  it 'renders the dora performers score visualization' do
    expect(dora_performers_score).to be_visible

    expect(dora_performers_score).to have_content format(_("DORA performers score for %{name} group"), name: group.name)
    expect(dora_performers_chart_title).to have_content _("Total projects (0) with DORA metrics")
  end
end

RSpec.shared_examples 'renders link to the feedback survey' do
  let(:feedback_survey) { find_by_testid('vsd-feedback-survey') }

  it 'renders feedback survey' do
    expect(feedback_survey).to be_visible
    expect(feedback_survey).to have_content _("To help us improve the Value Stream Management Dashboard, " \
                                              "please share feedback about your experience in this survey.")
  end
end

RSpec.shared_examples 'VSD renders as an analytics dashboard' do
  let(:legacy_vsd_testid) { "[data-testid='legacy-vsd']" }
  let(:dashboard_list_item_testid) { "[data-testid='dashboard-list-item']" }

  it 'renders as an analytics dashboard' do
    expect(page).not_to have_selector legacy_vsd_testid

    expect(find_by_testid('gridstack-grid')).to be_visible
  end

  it 'does not render the group dashboard listing' do
    expect(page).not_to have_selector(dashboard_list_item_testid)

    expect(page).to have_content _('Value Streams Dashboard')
  end
end

RSpec.shared_examples 'renders contributor count' do
  let(:contributor_count) { find_by_testid('dora-chart-metric-contributor-count') }

  it 'renders the contributor count metric' do
    expect(contributor_count).to be_visible
  end
end

RSpec.shared_examples 'does not render contributor count' do
  let(:contributor_count_testid) { "[data-testid='dora-chart-metric-contributor-count']" }

  it 'does not render the contributor count metric' do
    expect(page).not_to have_selector contributor_count_testid
  end
end

RSpec.shared_examples 'has value streams dashboard link' do
  it 'renders the value streams dashboard link' do
    dashboard_items = page.all(dashboard_list_item_testid)

    first_dashboard = dashboard_items[0]

    expect(dashboard_items.length).to eq(1)
    expect(first_dashboard).to have_content _('Value Streams Dashboard')
    expect(first_dashboard).to have_selector dashboard_by_gitlab_testid
  end
end
