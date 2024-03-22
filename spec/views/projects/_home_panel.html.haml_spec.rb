# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/_home_panel' do
  include ProjectForksHelper

  context 'home panel' do
    let(:project) { create(:project) }

    before do
      assign(:project, project)
    end

    it 'renders Vue app root' do
      render

      expect(rendered).to have_selector('#js-home-panel')
    end
  end

  context 'forks' do
    let(:source_project) { create(:project, :repository) }
    let(:project) { fork_project(source_project) }
    let(:user) { create(:user) }

    before do
      assign(:project, project)

      allow(view).to receive(:current_user).and_return(user)
    end

    context 'user can read fork source' do
      before do
        allow(view).to receive(:can?).with(user, :read_project, source_project).and_return(true)
      end

      it 'does not show the forked-from project' do
        render

        expect(rendered).not_to have_content("Forked from #{source_project.full_name}")
      end
    end

    context 'user cannot read fork source' do
      before do
        allow(view).to receive(:can?).with(user, :read_project, source_project).and_return(false)
      end

      it 'shows the message that forked project is inaccessible' do
        render

        expect(rendered).not_to have_content("Forked from an inaccessible project")
      end
    end
  end
end
