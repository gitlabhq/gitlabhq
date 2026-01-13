# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'explore/projects/index.html.haml', feature_category: :groups_and_projects do
  let_it_be(:user) { build_stubbed(:user) }

  before do
    allow(view).to receive_messages(current_user: user, explore_projects_app_data: {})
  end

  it 'renders the head partial' do
    render

    expect(rendered).to render_template('explore/projects/_head')
  end

  context 'when explore_projects_vue feature flag is enabled' do
    it 'does not render the Vue app' do
      render

      expect(rendered).to have_selector('#js-explore-projects')
    end

    it 'does not render the legacy partials' do
      render

      expect(rendered).not_to render_template('explore/projects/_nav')
      expect(rendered).not_to render_template('explore/projects/_projects')
    end
  end

  context 'when explore_projects_vue feature flag is disabled' do
    let_it_be(:projects) { [build_stubbed(:project, :public)] }

    before do
      stub_feature_flags(explore_projects_vue: false)
      assign(:projects, projects)
    end

    it 'does not render the Vue app' do
      render

      expect(rendered).not_to have_selector('#js-explore-projects')
    end

    it 'renders the legacy partials' do
      render

      expect(rendered).to render_template('explore/projects/_nav')
      expect(rendered).to render_template('explore/projects/_projects')
    end
  end
end
