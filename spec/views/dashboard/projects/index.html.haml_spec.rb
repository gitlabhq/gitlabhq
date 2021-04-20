# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'dashboard/projects/index.html.haml' do
  let_it_be(:user) { build(:user) }

  before do
    allow(view).to receive(:limited_counter_with_delimiter)
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:project_list_cache_key)
    allow(view).to receive(:time_ago_with_tooltip)
    allow(view).to receive(:project_icon)
    assign(:projects, [build(:project, name: 'awesome stuff')])
  end

  it 'shows the project the user is a member of in the list' do
    render

    expect(rendered).to have_content('awesome stuff')
  end

  it 'shows the "New project" button' do
    render

    expect(rendered).to have_link('New project')
  end
end
