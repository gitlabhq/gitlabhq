# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_ci_cd' do
  include RenderedHtml

  let_it_be(:admin) { create(:admin) }
  let_it_be(:application_setting) { build(:application_setting) }

  let_it_be(:limits_attributes) do
    {
      ci_instance_level_variables: 5,
      ci_pipeline_size: 10,
      ci_active_jobs: 20,
      ci_project_subscriptions: 30,
      ci_pipeline_schedules: 40,
      ci_needs_size_limit: 50,
      ci_registered_group_runners: 60,
      ci_registered_project_runners: 70,
      dotenv_size: 80,
      dotenv_variables: 90,
      pipeline_hierarchy_size: 300
    }
  end

  let_it_be(:default_plan_limits) { create(:plan_limits, :default_plan, **limits_attributes) }

  let(:page) { rendered_html }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:current_user) { admin }
    allow(view).to receive(:expanded) { true }
  end

  subject { render partial: 'admin/application_settings/ci_cd' }

  context 'limits' do
    before do
      assign(:plans, [default_plan_limits.plan])
    end

    it 'has fields for CI/CD limits', :aggregate_failures do
      subject

      expect(rendered).to have_field('Maximum number of Instance-level CI/CD variables that can be defined',
        type: 'number')
      expect(page.find_field('Maximum number of Instance-level CI/CD variables that can be defined').value).to eq('5')

      expect(rendered).to have_field('Maximum size of a dotenv artifact in bytes', type: 'number')
      expect(page.find_field('Maximum size of a dotenv artifact in bytes').value).to eq('80')

      expect(rendered).to have_field('Maximum number of variables in a dotenv artifact', type: 'number')
      expect(page.find_field('Maximum number of variables in a dotenv artifact').value).to eq('90')

      expect(rendered).to have_field('Maximum number of jobs in a single pipeline', type: 'number')
      expect(page.find_field('Maximum number of jobs in a single pipeline').value).to eq('10')

      expect(rendered).to have_field('Total number of jobs in currently active pipelines', type: 'number')
      expect(page.find_field('Total number of jobs in currently active pipelines').value).to eq('20')

      expect(rendered).to have_field('Maximum number of pipeline subscriptions to and from a project', type: 'number')
      expect(page.find_field('Maximum number of pipeline subscriptions to and from a project').value).to eq('30')

      expect(rendered).to have_field('Maximum number of pipeline schedules', type: 'number')
      expect(page.find_field('Maximum number of pipeline schedules').value).to eq('40')

      expect(rendered).to have_field('Maximum number of needs dependencies that a job can have', type: 'number')
      expect(page.find_field('Maximum number of needs dependencies that a job can have').value).to eq('50')

      expect(rendered).to have_field(
        'Maximum number of runners created or active in a group during the past seven days', type: 'number')
      expect(
        page.find_field('Maximum number of runners created or active in a group during the past seven days').value
      ).to eq('60')

      expect(rendered).to have_field(
        'Maximum number of runners created or active in a project during the past seven days', type: 'number')
      expect(
        page.find_field('Maximum number of runners created or active in a project during the past seven days').value
      ).to eq('70')

      expect(rendered).to have_field(
        "Maximum number of downstream pipelines in a pipeline's hierarchy tree", type: 'number'
      )
      expect(page.find_field("Maximum number of downstream pipelines in a pipeline's hierarchy tree").value)
      .to eq('300')
    end

    it 'does not display the plan name when there is only one plan' do
      subject

      expect(page).not_to have_selector('a[data-action="plan0"]')
    end
  end

  context 'with multiple plans' do
    let_it_be(:plan) { create(:plan, name: 'Ultimate') }
    let_it_be(:ultimate_plan_limits) { create(:plan_limits, plan: plan, **limits_attributes) }

    before do
      assign(:plans, [default_plan_limits.plan, ultimate_plan_limits.plan])
    end

    it 'displays the plan name when there is more than one plan' do
      subject

      expect(page).to have_content('Default')
      expect(page).to have_content('Ultimate')
      expect(page).to have_selector('a[data-action="plan0"]')
      expect(page).to have_selector('a[data-action="plan1"]')
    end
  end
end
