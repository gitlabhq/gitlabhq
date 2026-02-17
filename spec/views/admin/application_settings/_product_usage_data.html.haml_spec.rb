# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_product_usage_data.html.haml', feature_category: :service_ping do
  let_it_be(:admin) { build_stubbed(:admin) }
  let(:application_setting) { build(:application_setting) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive_messages(current_user: admin, expanded_by_default?: true)
  end

  context 'when environment variable is not set' do
    before do
      allow(Gitlab::Usage::ProductUsageDataSetting).to receive_messages(source: :database, enabled?: true)
    end

    it 'does not show the environment override warning' do
      render

      expect(rendered).not_to have_content('environment variable')
    end

    it 'enables the checkbox' do
      render

      expect(rendered).not_to have_css('input[name="application_setting[gitlab_product_usage_data_enabled]"][disabled]')
    end

    it 'enables the submit button' do
      render

      expect(rendered).not_to have_css('button[type="submit"][disabled]')
    end

    it 'enables the Snowplow checkbox' do
      render

      expect(rendered).not_to have_css('input[name="application_setting[snowplow_enabled]"][disabled]')
    end
  end

  context 'when environment variable is set' do
    context 'when set to true' do
      before do
        allow(Gitlab::Usage::ProductUsageDataSetting).to receive_messages(source: :environment, enabled?: true)
      end

      it 'shows the environment override warning with enabled status' do
        render

        expect(rendered).to have_content('GITLAB_PRODUCT_USAGE_DATA_ENABLED')
        expect(rendered).to have_content('enabled')
      end

      it 'disables the checkbox' do
        render

        expect(rendered).to have_css('input[name="application_setting[gitlab_product_usage_data_enabled]"][disabled]')
      end

      it 'disables the submit button' do
        render

        expect(rendered).to have_css('button[type="submit"][disabled]')
      end

      it 'checks the checkbox' do
        render

        expect(rendered).to have_css('input[name="application_setting[gitlab_product_usage_data_enabled]"][checked]')
      end

      it 'disables the Snowplow checkbox' do
        render

        expect(rendered).to have_css('input[name="application_setting[snowplow_enabled]"][disabled]')
      end
    end

    context 'when set to false' do
      before do
        allow(Gitlab::Usage::ProductUsageDataSetting).to receive_messages(source: :environment, enabled?: false)
      end

      it 'shows the environment override warning with disabled status' do
        render

        expect(rendered).to have_content('GITLAB_PRODUCT_USAGE_DATA_ENABLED')
        expect(rendered).to have_content('disabled')
      end

      it 'does not check the checkbox' do
        render

        checkbox_selector = 'input[name="application_setting[gitlab_product_usage_data_enabled]"][checked]'
        expect(rendered).not_to have_css(checkbox_selector)
      end
    end
  end
end
