# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/ci_cd.html.haml' do
  let_it_be(:app_settings) { build(:application_setting) }
  let_it_be(:user) { create(:admin) }

  let_it_be(:default_plan_limits) { create(:plan_limits, :default_plan, :with_package_file_sizes) }

  before do
    assign(:application_setting, app_settings)
    assign(:plans, [default_plan_limits.plan])
    allow(view).to receive(:current_user).and_return(user)
  end

  describe 'CI CD Runner Registration' do
    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(runner_registration_control: true)
      end

      it 'has the setting section' do
        render

        expect(rendered).to have_css("#js-runner-settings")
      end

      it 'renders the correct setting section content' do
        render

        expect(rendered).to have_content("Runner registration")
        expect(rendered).to have_content("If no options are selected, only administrators can register runners.")
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(runner_registration_control: false)
      end

      it 'does not have the setting section' do
        render

        expect(rendered).not_to have_css("#js-runner-settings")
      end

      it 'does not render the correct setting section content' do
        render

        expect(rendered).not_to have_content("Runner registration")
        expect(rendered).not_to have_content("If no options are selected, only administrators can register runners.")
      end
    end
  end
end
