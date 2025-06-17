# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/empty', feature_category: :groups_and_projects do
  let(:user) { build(:user) }
  let(:project) do
    ProjectPresenter.new(
      build_stubbed(:project, :empty_repo, statistics: build(:project_statistics)), current_user: user
    )
  end

  let(:can_admin_project_member) { true }

  before do
    allow(view).to receive(:can?).with(user, :invite_member, project).and_return(can_admin_project_member)
    allow(view).to receive_messages(experiment_enabled?: true, current_user: user)
    assign(:project, project)
  end

  context 'when user can push code on the project' do
    before do
      allow(view).to receive(:can?).with(user, :push_code, project).and_return(true)
    end

    it 'displays "git clone" instructions' do
      render

      expect(rendered).to have_content("git clone")
    end

    context 'when default branch name contains special shell characters' do
      let(:branch_name) { ';rm -rf /' }

      before do
        allow(project).to receive(:default_branch_or_main).and_return(branch_name)
      end

      it 'escapes the default branch name' do
        render

        expect(rendered).not_to have_content(branch_name)
        expect(rendered).to have_content(branch_name.shellescape)
      end
    end
  end

  context 'when user can not push code on the project' do
    before do
      allow(view).to receive(:can?).with(user, :push_code, project).and_return(false)
    end

    it 'does not display "git clone" instructions' do
      render

      expect(rendered).not_to have_content("git clone")
    end
  end

  context 'when project is archived' do
    let(:project) do
      ProjectPresenter.new(
        build_stubbed(:project, :empty_repo, :archived, statistics: build(:project_statistics)), current_user: user
      )
    end

    it 'shows archived notice' do
      render

      expect(rendered).to have_content('Archived')
    end
  end

  context 'with invite button on empty projects' do
    it 'shows invite members info', :aggregate_failures do
      render

      expect(rendered).to have_tracking(action: 'render', label: 'invite_members_empty_project')
      expect(rendered).to have_content('Invite your team')
      expect(rendered).to have_content('Add members to this project and start collaborating with your team.')
      expect(rendered).to have_selector('.js-invite-members-trigger')
      expect(rendered).to have_selector('[data-trigger-source=project_empty_page]')
    end

    context 'when user does not have permissions to invite members' do
      let(:can_admin_project_member) { false }

      it 'does not show invite member info', :aggregate_failures do
        render

        expect(rendered).not_to have_content('Invite your team')
        expect(rendered).not_to have_selector('.js-invite-members-trigger')
      end
    end
  end
end
