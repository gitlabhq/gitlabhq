# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'explore/analytics_dashboards/index.html.haml', feature_category: :custom_dashboards_foundation do
  it 'renders Vue app' do
    render

    expect(rendered).to have_selector('#js-explore-analytics-dashboards')
    expect(rendered).to have_selector('[data-explore-analytics-dashboards-path="/explore/analytics_dashboards"]')
  end
end
