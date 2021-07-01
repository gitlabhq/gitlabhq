# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/_home_panel' do
  include ProjectForksHelper

  context 'admin area link' do
    let(:project) { create(:project) }

    before do
      assign(:project, project)
    end

    it 'renders admin area link for admin' do
      allow(view).to receive(:current_user).and_return(create(:admin))

      render

      expect(rendered).to have_link(href: admin_project_path(project))
    end

    it 'does not render admin area link for non-admin' do
      allow(view).to receive(:current_user).and_return(create(:user))

      render

      expect(rendered).not_to have_link(href: admin_project_path(project))
    end

    it 'does not render admin area link for anonymous' do
      allow(view).to receive(:current_user).and_return(nil)

      render

      expect(rendered).not_to have_link(href: admin_project_path(project))
    end
  end

  context 'notifications' do
    let(:project) { create(:project) }

    before do
      assign(:project, project)

      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:can?).with(user, :read_project, project).and_return(false)
      allow(project).to receive(:license_anchor_data).and_return(false)
    end

    context 'when user is signed in' do
      let(:user) { create(:user) }

      before do
        notification_settings = user.notification_settings_for(project)
        assign(:notification_setting, notification_settings)
      end

      it 'renders Vue app root' do
        render

        expect(rendered).to have_selector('.js-vue-notification-dropdown')
      end
    end

    context 'when user is signed out' do
      let(:user) { nil }

      before do
        assign(:notification_setting, nil)
      end

      it 'does not render Vue app root' do
        render

        expect(rendered).not_to have_selector('.js-vue-notification-dropdown')
      end
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

  context 'project id' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }

    before do
      assign(:project, project)

      allow(view).to receive(:current_user).and_return(user)
      allow(project).to receive(:license_anchor_data).and_return(false)
    end

    context 'user can read project' do
      it 'is shown' do
        allow(view).to receive(:can?).with(user, :read_project, project).and_return(true)

        render

        expect(rendered).to have_content("Project ID: #{project.id}")
      end
    end

    context 'user cannot read project' do
      it 'is not shown' do
        allow(view).to receive(:can?).with(user, :read_project, project).and_return(false)

        render

        expect(rendered).not_to have_content("Project ID: #{project.id}")
      end
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
      it 'shows the forked-from project' do
        allow(view).to receive(:can?).with(user, :read_project, source_project).and_return(true)

        render

        expect(rendered).to have_content("Forked from #{source_project.full_name}")
      end
    end

    context 'user cannot read fork source' do
      it 'does not show the forked-from project' do
        allow(view).to receive(:can?).with(user, :read_project, source_project).and_return(false)

        render

        expect(rendered).to have_content("Forked from an inaccessible project")
      end
    end
  end
end
