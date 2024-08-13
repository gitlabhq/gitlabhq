# frozen_string_literal: true

RSpec.shared_examples 'renders usage overview metrics' do
  let(:usage_overview) { find_by_testid('panel-usage-overview') }

  it 'renders the metrics panel' do
    expect(usage_overview).to be_visible
    expect(usage_overview).to have_content format(_("Usage overview for %{title}"), title: panel_title)
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

RSpec.shared_examples 'renders usage overview background aggregation not enabled alert' do
  let(:vsd_background_aggregation_disabled_alert) { find_by_testid('vsd-background-aggregation-disabled-warning') }

  it 'renders background aggregation not enabled alert' do
    expect(vsd_background_aggregation_disabled_alert).to be_visible

    expect(vsd_background_aggregation_disabled_alert).to have_content _('Background aggregation not enabled')
    expect(vsd_background_aggregation_disabled_alert).to have_content _("To see usage overview, you must enable " \
    "background aggregation.")
  end
end

RSpec.shared_examples 'does not render usage overview background aggregation not enabled alert' do
  let(:vsd_background_aggregation_disabled_alert) { "[data-testid='vsd-background-aggregation-disabled-warning']" }

  it 'does not render background aggregation not enabled alert' do
    expect(page).not_to have_selector vsd_background_aggregation_disabled_alert
  end
end

RSpec.shared_examples 'renders metrics comparison table' do
  let(:metric_table) { find_by_testid('panel-dora-chart') }

  it 'renders the metrics comparison visualization' do
    expect(metric_table).to be_visible
    expect(metric_table).to have_content format(_("Metrics comparison for %{title}"), title: panel_title)
  end

  it "renders the available metrics" do
    wait_for_all_requests

    [
      ['lead-time-for-changes', _('Lead time for changes'), '3.0 d 40.0% 1.0 d 66.7% 0.0 d'],
      ['time-to-restore-service', _('Time to restore service'), '3.0 d 57.1% 5.0 d 66.7% 0.0 d'],
      ['lead-time', _('Lead time'), '4.0 d 33.3% 2.0 d 50.0% -'],
      ['cycle-time', _('Cycle time'), '3.0 d 50.0% 1.0 d 66.7% -'],
      ['issues', _('Issues created'), '20 33.3% 10 50.0% -'],
      ['issues-completed', _('Issues closed'), '20 33.3% 10 50.0% -'],
      ['deploys', _('Deploys'), '10 25.0% 5 50.0% -'],
      ['merge-request-throughput', _('Merge request throughput'), '7 16.7% 5 28.6% -'],
      ['median-time-to-merge', _('Median time to merge'), '- - -'],
      ['vulnerability-critical', _('Critical vulnerabilities over time'), '5 3 -'],
      ['vulnerability-high', _('High vulnerabilities over time'), '4 2 -'],

      # The values of these metrics are dependent on the length of the month they are in. Due to the high
      # flake risk associated with them, we only validate the expected structure of the table row instead
      # of the actual metric values.
      ['deployment-frequency', _('Deployment frequency'), %r{ 0\.\d+/d \d+\.\d% 0\.\d+/d \d+\.\d% 0\.0/d}],
      ['change-failure-rate', _('Change failure rate'), %r{0\.0% \d+\.\d% \d+\.\d% \d+\.\d% \d+\.\d%}]
    ].each do |id, name, values|
      row = find_by_testid("dora-chart-metric-#{id}")

      expect(row).to be_visible
      expect(row).to have_content name
      expect(row).to have_content values
    end
  end
end

RSpec.shared_examples 'renders dora performers score' do
  let(:dora_performers_score) { find_by_testid('panel-dora-performers-score') }
  let(:dora_performers_chart_title) { find_by_testid('dora-performers-score-chart-title') }

  it 'renders the dora performers score visualization' do
    expect(dora_performers_score).to be_visible

    expect(dora_performers_score).to have_content format(_("DORA performers score for %{name} group"), name: group.name)
    expect(dora_performers_chart_title).to have_content _("Total projects (3) with DORA metrics")

    within dora_performers_score do
      legend = find_by_testid('gl-chart-legend')
      expect(legend).to have_content 'High Avg: 1 · Max: 1'
      expect(legend).to have_content 'Medium Avg: 750m · Max: 1'
      expect(legend).to have_content 'Low Avg: 750m · Max: 2'
      expect(legend).to have_content 'Not included Avg: 500m · Max: 1'
    end
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
  let(:dashboard_list_item_testid) { "[data-testid='dashboard-list-item']" }

  it 'renders as an analytics dashboard' do
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
