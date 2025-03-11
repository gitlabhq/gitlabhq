# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'dashboard/projects/index.html.haml', feature_category: :groups_and_projects do
  let_it_be(:user) { build(:user) }

  before do
    allow(view).to receive(:limited_counter_with_delimiter)
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:time_ago_with_tooltip)
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

    it 'does not render the "New project" button' do
      expect(rendered).not_to have_link('New project')
    end

    it 'does not render the "Explore projects" button' do
      expect(rendered).not_to have_link('Explore projects')
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

    it 'does render the "New project" button' do
      expect(rendered).to have_link('New project')
    end

    it 'does render the "Explore projects" button' do
      expect(rendered).to have_link('Explore projects')
    end
  end
end
