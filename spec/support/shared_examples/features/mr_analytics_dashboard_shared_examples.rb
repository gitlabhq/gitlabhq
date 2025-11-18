# frozen_string_literal: true

RSpec.shared_examples 'MR analytics renders as an analytics dashboard' do
  let(:dashboard_list_item_testid) { "[data-testid='dashboard-list-item']" }

  it 'renders MR analytics page correctly' do
    expect(find_by_testid('gridstack-grid')).to be_visible
    expect(page).not_to have_selector(dashboard_list_item_testid)
    expect(page).to have_text _('Merge request analytics')
    expect(page).to have_text _('Get insights into your merge request lifecycle and view trends over time.')

    expect(find_by_testid('dashboard-filters-date-range')).to be_visible
    expect(find_by_testid('dashboard-filters-filtered-search')).to be_visible
  end
end

RSpec.shared_examples 'renders `Mean time to merge` panel with correct value' do |expected_value:|
  it 'renders correct value in `Mean time to merge` panel' do
    within_testid('panel-mean-time-to-merge') do
      expect(page).to have_text _('Mean time to merge')
      expect(page).to have_text expected_value
    end
  end
end

RSpec.shared_examples 'renders chart in `Throughput` panel' do
  it 'renders area chart visualization in `Throughput` panel' do
    within_testid('panel-merge-requests-over-time') do
      expect(page).to have_text _('Throughput')
      expect(page).to have_selector('[data-testid="dashboard-visualization-area-chart"]')
    end
  end
end

RSpec.shared_examples 'renders merge requests in table in `Merge Requests` panel' do
  it 'renders merge requests in table in `Merge Requests` panel' do
    within_testid('panel-merge-requests-throughput-table') do
      table_rows = all('tbody tr')

      expect(page).to have_text('Merge Requests')
      expect(table_rows.count).to eq(expected_mrs.size)

      expected_mrs.each_with_index do |merge_request, i|
        expect(table_rows[i]).to have_content merge_request.title
        expect(table_rows[i]).to have_content merge_request.milestone.title if merge_request.milestone.present?
      end
    end
  end
end
