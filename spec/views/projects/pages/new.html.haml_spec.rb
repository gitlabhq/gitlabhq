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

  describe 'with onboarding wizard feature enabled' do
    before do
      Feature.enable(:use_pipeline_wizard_for_pages)
    end

    it "shows the onboarding wizard" do
      render
      expect(rendered).to have_selector('#js-pages')
    end
  end

  describe 'with onboarding wizard feature disabled' do
    before do
      Feature.disable(:use_pipeline_wizard_for_pages)
    end

    it "does not show the onboarding wizard" do
      render
      expect(rendered).not_to have_selector('#js-pages')
    end

    it "renders the usage instructions" do
      render
      expect(rendered).to render_template('projects/pages/_use')
    end
  end
end
