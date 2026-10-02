# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'projects/pages/new' do
  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }

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
