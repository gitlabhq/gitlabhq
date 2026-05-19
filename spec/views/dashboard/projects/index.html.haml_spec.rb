# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'dashboard/projects/index.html.haml', feature_category: :groups_and_projects do
  let_it_be(:user) { build(:user) }

  before do
    allow(view).to receive_messages(
      limited_counter_with_delimiter: nil,
      current_user: user,
      time_ago_with_tooltip: nil,
      dashboard_projects_app_data: '{}'
    )
  end

  context 'when show_dashboard_projects_welcome_page? is true' do
    before do
      allow(view).to receive(:show_dashboard_projects_welcome_page?).and_return(true)
      render
    end

    it 'renders the zero_authorized_projects partial and not the projects Vue app' do
      expect(rendered).not_to have_selector('#js-your-work-projects-app')
      expect(rendered).to render_template('dashboard/projects/_zero_authorized_projects')
    end
  end

  context 'when show_dashboard_projects_welcome_page? is false' do
    before do
      allow(view).to receive(:show_dashboard_projects_welcome_page?).and_return(false)
      render
    end

    it 'renders the projects Vue app and not the zero_authorized_projects partial' do
      expect(rendered).to have_selector('#js-your-work-projects-app')
      expect(rendered).not_to render_template('dashboard/projects/_zero_authorized_projects')
    end
  end
end
