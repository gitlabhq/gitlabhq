# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_package_registry' do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:default_plan_limits) { create(:plan_limits, :default_plan, :with_package_file_sizes) }
  let_it_be(:application_setting) { build(:application_setting) }

  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:current_user) { admin }
    allow(view).to receive(:expanded) { true }
  end

  subject { render partial: 'admin/application_settings/package_registry' }

  context 'package file size limits' do
    before do
      assign(:plans, [default_plan_limits.plan])
    end

    it 'has fields for max package file sizes' do
      subject

      expect(rendered).to have_field('Maximum Conan package file size in bytes', type: 'number')
      expect(page.find_field('Maximum Conan package file size in bytes').value).to eq(default_plan_limits.conan_max_file_size.to_s)

      expect(rendered).to have_field('Maximum Maven package file size in bytes', type: 'number')
      expect(page.find_field('Maximum Maven package file size in bytes').value).to eq(default_plan_limits.maven_max_file_size.to_s)

      expect(rendered).to have_field('Maximum npm package file size in bytes', type: 'number')
      expect(page.find_field('Maximum npm package file size in bytes').value).to eq(default_plan_limits.npm_max_file_size.to_s)

      expect(rendered).to have_field('Maximum NuGet package file size in bytes', type: 'number')
      expect(page.find_field('Maximum NuGet package file size in bytes').value).to eq(default_plan_limits.nuget_max_file_size.to_s)

      expect(rendered).to have_field('Maximum PyPI package file size in bytes', type: 'number')
      expect(page.find_field('Maximum PyPI package file size in bytes').value).to eq(default_plan_limits.pypi_max_file_size.to_s)
    end

    it 'does not display the plan name when there is only one plan' do
      subject

      expect(page).not_to have_content('Default')
    end
  end

  context 'with multiple plans' do
    let_it_be(:plan) { create(:plan, name: 'Ultimate') }
    let_it_be(:ultimate_plan_limits) { create(:plan_limits, :with_package_file_sizes, plan: plan) }

    before do
      assign(:plans, [default_plan_limits.plan, ultimate_plan_limits.plan])
    end

    it 'displays the plan name when there is more than one plan' do
      subject

      expect(page).to have_content('Default')
      expect(page).to have_content('Ultimate')
    end
  end
end
