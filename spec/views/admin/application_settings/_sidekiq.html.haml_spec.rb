# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_sidekiq.html.haml', feature_category: :sidekiq do
  let(:app_settings) { build_stubbed(:application_setting, sidekiq_timezone_override: 'Europe/London') }

  before do
    assign(:application_setting, app_settings)
    stub_application_setting(sidekiq_timezone_override: 'Europe/London')
  end

  it 'renders the job size limit fields', :aggregate_failures do
    render

    expect(rendered).to have_field('Sidekiq job compression threshold (bytes)')
    expect(rendered).to have_field('Sidekiq job size limit (bytes)')
  end

  it 'renders the cron jobs timezone dropdown', :aggregate_failures do
    render

    expect(rendered).to have_content('Cron jobs time zone')
    expect(rendered).to have_css('.js-timezone-dropdown')

    view_model = Gitlab::Json::SafeParser.parse(Nokogiri::HTML(rendered).at_css('.js-timezone-dropdown')['data-view-model'])

    expect(view_model).to include(
      'inputId' => 'application_setting_sidekiq_timezone_override',
      'value' => 'Europe/London',
      'name' => 'application_setting[sidekiq_timezone_override]',
      'defaultText' => 'System default'
    )
    expect(view_model['timezoneData']).to be_present
  end
end
