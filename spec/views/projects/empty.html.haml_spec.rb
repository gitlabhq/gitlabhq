# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/empty' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { ProjectPresenter.new(create(:project, :empty_repo), current_user: user) }

  before do
    allow(view).to receive(:experiment_enabled?).and_return(true)
    allow(view).to receive(:current_user).and_return(user)
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

  context 'project is archived' do
    let(:project) { ProjectPresenter.new(create(:project, :empty_repo, :archived), current_user: user) }

    it 'shows archived notice' do
      render

      expect(rendered).to have_content('Archived project!')
    end
  end

  context 'with invite button on empty projects' do
    let(:can_import_members) { true }

    before do
      allow(view).to receive(:can_import_members?).and_return(can_import_members)
    end

    it 'shows invite members info', :aggregate_failures do
      render

      expect(rendered).to have_selector('[data-track-event=render]')
      expect(rendered).to have_selector('[data-track-label=invite_members_empty_project]')
      expect(rendered).to have_content('Invite your team')
      expect(rendered).to have_content('Add members to this project and start collaborating with your team.')
      expect(rendered).to have_selector('.js-invite-members-trigger')
      expect(rendered).to have_selector('.js-invite-members-modal')
      expect(rendered).to have_selector('[data-label=invite_members_empty_project]')
      expect(rendered).to have_selector('[data-event=click_button]')
      expect(rendered).to have_selector('[data-trigger-source=project-empty-page]')
    end

    context 'when user does not have permissions to invite members' do
      let(:can_import_members) { false }

      it 'does not show invite member info', :aggregate_failures do
        render

        expect(rendered).not_to have_content('Invite your team')
        expect(rendered).not_to have_selector('.js-invite-members-trigger')
        expect(rendered).not_to have_selector('.js-invite-members-modal')
      end
    end
  end
end
