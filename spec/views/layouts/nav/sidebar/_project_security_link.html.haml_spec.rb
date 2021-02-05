# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/sidebar/_project_security_link' do
  let_it_be_with_reload(:project) { create(:project) }
  context 'on security configuration' do
    before do
      assign(:project, project)
      allow(controller).to receive(:controller_name).and_return('configuration')
      allow(controller).to receive(:controller_path).and_return('projects/security/configuration')
      allow(controller).to receive(:action_name).and_return('show')
      allow(view).to receive(:any_project_nav_tab?).and_return(true)
      allow(view).to receive(:project_nav_tab?).and_return(true)
    end

    it 'activates Security & Compliance tab' do
      render

      expect(rendered).to have_css('li.active', text: 'Security & Compliance')
    end

    it 'activates Configuration sub tab' do
      render

      expect(rendered).to have_css('.sidebar-sub-level-items > li.active', text: 'Configuration')
    end
  end
end
