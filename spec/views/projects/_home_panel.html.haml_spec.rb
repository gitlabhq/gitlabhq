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

  context 'badges' do
    shared_examples 'show badges' do
      it 'renders the all badges' do
        render

        expect(rendered).to have_selector('.project-badges a')

        badges.each do |badge|
          expect(rendered).to have_link(href: badge.rendered_link_url)
        end
      end
    end

    let(:user) { create(:user) }
    let(:badges) { project.badges }

    before do
      assign(:project, project)

      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:can?).with(user, :read_project, project).and_return(false)
      allow(project).to receive(:license_anchor_data).and_return(false)

      stub_feature_flags(project_overview_reorg: false)
    end

    context 'has no badges' do
      let(:project) { create(:project) }

      it 'does not render any badge' do
        render

        expect(rendered).not_to have_selector('.project-badges')
      end
    end

    context 'only has group badges' do
      let(:group) { create(:group) }
      let(:project) { create(:project, namespace: group) }

      before do
        create(:group_badge, group: project.group)
      end

      it_behaves_like 'show badges'
    end

    context 'only has project badges' do
      let(:project) { create(:project) }

      before do
        create(:project_badge, project: project)
      end

      it_behaves_like 'show badges'
    end

    context 'has both group and project badges' do
      let(:group) { create(:group) }
      let(:project) { create(:project, namespace: group) }

      before do
        create(:project_badge, project: project)
        create(:group_badge, group: project.group)
      end

      it_behaves_like 'show badges'
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
