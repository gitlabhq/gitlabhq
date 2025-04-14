# frozen_string_literal: true

RSpec.shared_examples 'page with product usage data collection banner' do
  before do
    sign_in(user)
    allow(user).to receive(:can_admin_all_resources?).and_return(true)
  end

  it 'hides product usage data collection callout if user has dismissed it' do
    allow(user).to receive(:dismissed_callout?).and_return(true)

    visit page_path
    expect(page).not_to have_selector '[data-testid="product-usage-data-collection-banner"]'
  end

  it 'shows dismissable product usage data collection callout if not dismissed yet', :js do
    allow(user).to receive(:dismissed_callout?).and_return(false)

    visit page_path
    expect(page).to have_selector '[data-testid="product-usage-data-collection-banner"]'

    page.within('[data-testid="product-usage-data-collection-banner"]') do
      expect(page).to have_selector('[data-track-action=dismiss_banner]')
      expect(page).to have_selector('[data-track-label=product_usage_data_collection_banner]')
      click_button "Dismiss product usage data collection notice"
    end

    expect(page).not_to have_selector '[data-testid="product-usage-data-collection-banner"]'
  end
end
