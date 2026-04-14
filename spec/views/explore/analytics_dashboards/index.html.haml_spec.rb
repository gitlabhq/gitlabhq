# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'explore/analytics_dashboards/index.html.haml', feature_category: :custom_dashboards_foundation do
  it 'page header' do
    render

    expect(rendered).to have_css('h1', text: 'Analytics dashboards')
    expect(rendered).to have_content('Keep your teams aligned around the metrics that matter most')
  end

  it 'renders Vue app' do
    render

    expect(rendered).to have_selector('#js-explore-analytics-dashboards')
  end
end
