# frozen_string_literal: true

RSpec.shared_examples 'DORA metrics analytics renders as an analytics dashboard' do |days_back: 180|
  let(:dashboard_list_item_testid) { "[data-testid='dashboard-list-item']" }

  it 'renders DORA metrics analytics page correctly' do
    expect(find_by_testid('gridstack-grid')).to be_visible
    expect(page).not_to have_selector(dashboard_list_item_testid)
    expect(page).to have_text _('DORA metrics analytics')
    expect(page).to have_text _("View current DORA metric performance and historical trends " \
      "to analyze DevOps efficiency over time.")

    expect(find_by_testid('dashboard-filters-date-range')).to have_text format(_('Last %{days} days'),
      days: days_back)
  end
end

RSpec.shared_examples 'renders DORA metrics analytics stats' do |days_back: 180|
  using RSpec::Parameterized::TableSyntax

  let(:expected_dora_metrics_stats) { ['0 /day', '0.0 %', '0.0 days', '0.0 days'] }

  let(:deployment_frequency) { expected_dora_metrics_stats.first }
  let(:change_failure_rate) { expected_dora_metrics_stats.second }
  let(:time_to_restore_service) { expected_dora_metrics_stats.third }
  let(:lead_time_for_changes) { expected_dora_metrics_stats.fourth }

  where(:panel_testid, :title, :expected_value) do
    'deployment-frequency-average' | _('Deployment frequency average') | ref(:deployment_frequency)
    'change-failure-rate' | _('Change failure rate') | ref(:change_failure_rate)
    'time-to-restore-service-median' | _('Time to restore service median') | ref(:time_to_restore_service)
    'lead-time-for-changes-median' | _('Lead time for changes median') | ref(:lead_time_for_changes)
  end

  with_them do
    it "renders #{params[:title]} visualization with correct data" do
      panel = find_by_testid("panel-#{panel_testid}")

      expect(panel).to be_visible
      expect(panel).to have_text title
      expect(panel).to have_text format(_("Last %{days} days"), days: days_back)
      expect(panel).to have_text expected_value
    end
  end
end

RSpec.shared_examples 'renders DORA metrics stats with zero values' do
  it_behaves_like 'renders DORA metrics analytics stats'
end

RSpec.shared_examples 'renders DORA metrics time series charts' do |days_back: 180|
  using RSpec::Parameterized::TableSyntax

  let(:deployment_frequency_legend) do
    format(
      _("Deployment frequency Average (last %{days}d) No deployments during this period"), days: days_back)
  end

  let(:change_failure_rate_legend) do
    format(
      _("Change failure rate Median time (last %{days}d) No incidents during this period"), days: days_back)
  end

  let(:time_to_restore_service_legend) do
    format(
      _("Time to restore service Median time (last %{days}d) No incidents during this period"), days: days_back)
  end

  let(:lead_time_for_changes_legend) do
    format(
      _("Lead time for changes Median (last %{days}d) No merge requests were deployed during this period"),
      days: days_back
    )
  end

  where(:panel_testid, :title, :expected_legend) do
    'deployment-frequency-over-time' | _('Deployment frequency over time') | ref(:deployment_frequency_legend)
    'change-failure-rate-over-time' | _('Change failure rate over time') | ref(:change_failure_rate_legend)
    'time-to-restore-service-over-time' | _('Time to restore service over time') |
      ref(:time_to_restore_service_legend)
    'lead-time-for-changes-over-time' | _('Lead time for changes over time') | ref(:lead_time_for_changes_legend)
  end

  with_them do
    it "renders #{params[:title]} chart with correct data" do
      panel_selector = "panel-#{panel_testid}"
      panel = find_by_testid(panel_selector)

      expect(panel).to be_visible
      expect(panel).to have_text title
      expect(panel).to have_selector("[data-testid='dashboard-visualization-line-chart']")

      within_testid(panel_selector) do
        expect(find_by_testid('gl-chart-legend')).to have_text expected_legend
      end
    end
  end
end

RSpec.shared_examples 'renders DORA metrics chart panels with empty states' do
  using RSpec::Parameterized::TableSyntax

  where(:panel_testid, :title) do
    'deployment-frequency-over-time' | _('Deployment frequency over time')
    'change-failure-rate-over-time' | _('Change failure rate over time')
    'time-to-restore-service-over-time' | _('Time to restore service over time')
    'lead-time-for-changes-over-time' | _('Lead time for changes over time')
  end

  with_them do
    it "renders #{params[:title]} chart panel with empty state" do
      panel = find_by_testid("panel-#{panel_testid}")
      expect(panel).to be_visible
      expect(panel).to have_text title
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
