# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'projects/pages/new' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, maintainers: user) }

  before do
    allow(project).to receive(:show_pages_onboarding?).and_return(true)

    assign(:project, project)
    allow(view).to receive(:current_user).and_return(user)
  end

  it "shows the onboarding wizard" do
    render
    expect(rendered).to have_selector('#js-pages')
  end
end
