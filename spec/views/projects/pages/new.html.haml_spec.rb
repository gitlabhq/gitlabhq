# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'projects/pages/new' do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  before do
    allow(project).to receive(:show_pages_onboarding?).and_return(true)
    project.add_maintainer(user)

    assign(:project, project)
    allow(view).to receive(:current_user).and_return(user)
  end

  it "shows the onboarding wizard" do
    render
    expect(rendered).to have_selector('#js-pages')
  end
end
