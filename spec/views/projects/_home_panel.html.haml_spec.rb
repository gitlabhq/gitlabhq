require 'spec_helper'

describe 'projects/_home_panel' do
  let(:group) { create(:group) }
  let(:project) { create(:project, :public, namespace: group) }

  let(:notification_settings) do
    user&.notification_settings_for(project)
  end

  before do
    assign(:project, project)
    assign(:notification_setting, notification_settings)

    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:can?).and_return(false)
  end

  context 'when user is signed in' do
    let(:user) { create(:user) }

    it 'makes it possible to set notification level' do
      render

      expect(view).to render_template('shared/notifications/_button')
      expect(rendered).to have_selector('.notification-dropdown')
    end
  end

  context 'when user is signed out' do
    let(:user) { nil }

    it 'is not possible to set notification level' do
      render

      expect(rendered).not_to have_selector('.notification_dropdown')
    end
  end

  context 'when project' do
    let!(:user) { create(:user) }
    let(:badges) { project.badges }

    context 'has no badges' do
      it 'should not render any badge' do
        render

        expect(rendered).to have_selector('.project-badges')
        expect(rendered).not_to have_selector('.project-badges > a')
      end
    end

    shared_examples 'show badges' do
      it 'should render the all badges' do
        render

        expect(rendered).to have_selector('.project-badges a')

        badges.each do |badge|
          expect(rendered).to have_link(href: badge.rendered_link_url)
        end
      end
    end

    context 'only has group badges' do
      before do
        create(:group_badge, group: project.group)
      end

      it_behaves_like 'show badges'
    end

    context 'only has project badges' do
      before do
        create(:project_badge, project: project)
      end

      it_behaves_like 'show badges'
    end

    context 'has both group and project badges' do
      before do
        create(:project_badge, project: project)
        create(:group_badge, group: project.group)
      end

      it_behaves_like 'show badges'
    end
  end
end
