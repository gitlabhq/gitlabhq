# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'dashboard/projects/shared/_common.html.haml', feature_category: :groups_and_projects do
  let_it_be(:user) { build(:user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  it 'renders #js-your-work-projects-app and not legacy project list' do
    render

    expect(rendered).to have_selector('#js-your-work-projects-app')
    expect(rendered).not_to render_template('dashboard/projects/_projects')
  end
end
