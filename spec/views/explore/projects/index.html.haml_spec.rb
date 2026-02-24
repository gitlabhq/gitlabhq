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

  it 'renders Vue app' do
    render

    expect(rendered).to have_selector('#js-explore-projects')
  end
end
