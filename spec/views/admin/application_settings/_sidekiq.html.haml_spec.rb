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

  describe 'managed timezone setting' do
    let(:managed_banner) { 'This setting is managed by GitLab Helm Chart and cannot be changed from here.' }

    def view_model
      Gitlab::Json::SafeParser.parse(Nokogiri::HTML(rendered).at_css('.js-timezone-dropdown')['data-view-model'])
    end

    context 'when the timezone setting is managed' do
      before do
        Gitlab::ManagedSettings.reset!
        stub_const('Gitlab::ManagedSettings::PATH',
          Rails.root.join('spec/fixtures/managed_settings/valid.yml'))
      end

      after do
        Gitlab::ManagedSettings.reset!
      end

      it 'disables the dropdown and shows the managed banner', :aggregate_failures do
        render

        expect(rendered).to have_content(managed_banner)
        expect(view_model['disabled']).to be(true)
      end
    end

    context 'when the timezone setting is not managed' do
      before do
        Gitlab::ManagedSettings.reset!
        stub_const('Gitlab::ManagedSettings::PATH',
          Rails.root.join('spec/fixtures/managed_settings/does_not_exist.yml'))
      end

      after do
        Gitlab::ManagedSettings.reset!
      end

      it 'does not disable the dropdown or show the banner', :aggregate_failures do
        render

        expect(rendered).not_to have_content(managed_banner)
        expect(view_model['disabled']).to be(false)
      end
    end
  end
end
