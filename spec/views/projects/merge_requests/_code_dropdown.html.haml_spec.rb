# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/merge_requests/_code_dropdown.html.haml', feature_category: :code_review_workflow do
  include Devise::Test::ControllerHelpers

  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:merge_request) do
    build_stubbed(:merge_request, source_project: project, target_project: project)
  end

  before do
    assign(:project, project)
    assign(:merge_request, merge_request)

    allow(view).to receive(:current_user).and_return(user)
  end

  def render_dropdown(enabled)
    render partial: 'projects/merge_requests/code_dropdown',
      locals: { code_dropdown_vue_enabled: enabled }
  end

  it 'mounts the Vue dropdown when enabled' do
    render_dropdown(true)

    expect(rendered).to have_css('.js-mr-code-dropdown')
    expect(rendered).not_to have_css('.dropdown-menu')
  end

  it 'renders the legacy dropdown when disabled' do
    render_dropdown(false)

    expect(rendered).to have_css('.dropdown-menu')
    expect(rendered).not_to have_css('.js-mr-code-dropdown')
  end
end
