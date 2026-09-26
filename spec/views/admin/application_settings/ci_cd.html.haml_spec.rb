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

  describe 'CI CD Runners', feature_category: :runner_core do
    it 'has the setting section' do
      render

      expect(rendered).to have_css("#js-runner-settings")
    end

    it 'renders the correct setting section content' do
      render

      expect(rendered).to have_content("Runner registration")
      expect(rendered).to have_content("Allow runner registration token")
      expect(rendered).to have_content("Members of the project can create runners")
      expect(rendered).to have_content("Members of the group can create runners")
    end
  end

  describe 'Job logs', feature_category: :continuous_integration do
    it 'renders trace update interval settings', :aggregate_failures do
      render

      expect(rendered).to have_field('Job log update interval', type: 'number', with: '60')
      expect(rendered).to have_field('Job log update interval when open', type: 'number', with: '3')
      expect(rendered).to have_selector(
        'input[name="application_setting[ci_job_trace_update_interval_when_being_watched]"][max="60"]'
      )
    end
  end
end
