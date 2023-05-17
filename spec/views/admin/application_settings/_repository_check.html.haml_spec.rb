# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_repository_check.html.haml', feature_category: :source_code_management do
  let_it_be(:user) { create(:admin) }
  let_it_be(:application_setting) { build(:application_setting) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:current_user).and_return(user)
  end

  describe 'repository checks' do
    it 'has the setting subsection' do
      render

      expect(rendered).to have_content('Repository checks')
    end

    it 'renders the correct setting subsection content' do
      render

      expect(rendered).to have_field('Enable repository checks')
      expect(rendered).to have_link(
        'Clear all repository checks',
        href: clear_repository_check_states_admin_application_settings_path
      )
    end
  end

  describe 'housekeeping' do
    it 'has the setting subsection' do
      render

      expect(rendered).to have_content('Housekeeping')
    end

    it 'renders the correct setting subsection content' do
      render

      expect(rendered).to have_field('Enable automatic repository housekeeping')
      expect(rendered).to have_field('Optimize repository period')
    end
  end

  describe 'inactive project deletion' do
    let_it_be(:application_setting) do
      build(
        :application_setting,
        delete_inactive_projects: true,
        inactive_projects_delete_after_months: 2,
        inactive_projects_min_size_mb: 250,
        inactive_projects_send_warning_email_after_months: 1
      )
    end

    it 'has the setting subsection' do
      render

      expect(rendered).to have_content('Inactive project deletion')
    end

    it 'renders the correct setting subsection content' do
      render

      expect(rendered).to have_selector('.js-inactive-project-deletion-form')
      expect(rendered).to have_selector('[data-delete-inactive-projects="true"]')
      expect(rendered).to have_selector('[data-inactive-projects-delete-after-months="2"]')
      expect(rendered).to have_selector('[data-inactive-projects-min-size-mb="250"]')
      expect(rendered).to have_selector('[data-inactive-projects-send-warning-email-after-months="1"]')
    end
  end
end
