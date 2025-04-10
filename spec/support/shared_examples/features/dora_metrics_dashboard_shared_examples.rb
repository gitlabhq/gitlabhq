# frozen_string_literal: true

RSpec.shared_examples 'DORA metrics analytics renders as an analytics dashboard' do |days_back: 180|
  let(:dashboard_list_item_testid) { "[data-testid='dashboard-list-item']" }

  it 'renders DORA metrics analytics page correctly' do
    expect(find_by_testid('gridstack-grid')).to be_visible
    expect(page).not_to have_selector(dashboard_list_item_testid)
    expect(page).to have_text _('DORA metrics analytics')
    expect(page).to have_text _("View current DORA metric performance and historical trends " \
      "to analyze DevOps efficiency over time.")

    within find_by_testid('dashboard-filters') do
      expect(find_by_testid('dashboard-filters-date-range')).to have_text format(_('Last %{days} days'),
        days: days_back)
    end
  end
end

RSpec.shared_examples 'renders DORA metrics analytics stats' do |days_back: 180|
  let(:expected_dora_metrics_stats) { ['0 /day', '0.0 %', '0.0 days', '0.0 days'] }

  it 'renders each of the available stats with the correct values' do
    deployment_frequency, change_failure_rate, time_to_restore_service, lead_time_for_changes =
      expected_dora_metrics_stats

    [
      ['deployment-frequency-average', _('Deployment frequency average'), deployment_frequency],
      ['change-failure-rate', _('Change failure rate'), change_failure_rate],
      ['time-to-restore-service-median', _('Time to restore service median'), time_to_restore_service],
      ['lead-time-for-changes-median', _('Lead time for changes median'), lead_time_for_changes]
    ].each do |id, name, value|
      stat = find_by_testid("panel-#{id}")
      expect(stat).to be_visible
      expect(stat).to have_text name
      expect(stat).to have_text format(_("Last %{days} days"), days: days_back)
      expect(stat).to have_text value
    end
  end
end

RSpec.shared_examples 'renders DORA metrics stats with zero values' do
  it_behaves_like 'renders DORA metrics analytics stats'
end

RSpec.shared_examples 'renders DORA metrics time series charts' do |days_back: 180|
  it 'renders DORA metrics time series charts with correct values' do
    deployment_frequency_legend = format(
      _("Deployment frequency Average (last %{days}d) No deployments during this period"), days: days_back)
    change_failure_rate_legend = format(
      _("Change failure rate Median time (last %{days}d) No incidents during this period"), days: days_back)
    time_to_restore_service_legend = format(
      _("Time to restore service Median time (last %{days}d) No incidents during this period"), days: days_back)
    lead_time_for_changes_legend = format(
      _("Lead time for changes Median (last %{days}d) No merge requests were deployed during this period"),
      days: days_back
    )

    [
      ['deployment-frequency-over-time', _('Deployment frequency over time'), deployment_frequency_legend],
      ['change-failure-rate-over-time', _('Change failure rate over time'), change_failure_rate_legend],
      ['time-to-restore-service-over-time', _('Time to restore service over time'), time_to_restore_service_legend],
      ['lead-time-for-changes-over-time', _('Lead time for changes over time'), lead_time_for_changes_legend]
    ].each do |id, name, chart_legend_content|
      panel = find_by_testid("panel-#{id}")
      expect(panel).to be_visible
      expect(panel).to have_text name
      expect(panel).to have_selector("[data-testid='dashboard-visualization-line-chart']")

      within panel do
        expect(find_by_testid('gl-chart-legend')).to have_text chart_legend_content
      end
    end
  end
end

RSpec.shared_examples 'renders DORA metrics chart panels with empty states' do
  it 'renders each DORA metric chart panel with an empty state' do
    [
      ['deployment-frequency-over-time', _('Deployment frequency over time')],
      ['change-failure-rate-over-time', _('Change failure rate over time')],
      ['time-to-restore-service-over-time', _('Time to restore service over time')],
      ['lead-time-for-changes-over-time', _('Lead time for changes over time')]
    ].each do |id, name|
      panel = find_by_testid("panel-#{id}")
      expect(panel).to be_visible
      expect(panel).to have_text name
      expect(panel).to have_text _('No results match your query or filter.')
    end
  end
end

RSpec.shared_examples 'updates DORA metrics visualizations when filters applied' do |days_back:|
  include ListboxHelpers

  context 'when date range filter changes' do
    let(:date_range_filter) { find_by_testid('dashboard-filters-date-range') }

    before do
      within date_range_filter do
        toggle_listbox
        select_listbox_item(format(_('Last %{days} days'), days: days_back), exact_text: true)

        wait_for_requests
      end
    end

    it_behaves_like 'DORA metrics analytics renders as an analytics dashboard', days_back: days_back

    it_behaves_like 'renders DORA metrics analytics stats', days_back: days_back do
      let(:expected_dora_metrics_stats) { filtered_dora_metrics_stats }
    end

    it_behaves_like 'renders DORA metrics time series charts', days_back: days_back
  end
end
