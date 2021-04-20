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

  describe 'invite_members_empty_project_version_a experiment' do
    let(:can_import_members) { true }

    before do
      allow(view).to receive(:can_import_members?).and_return(can_import_members)
    end

    shared_examples_for 'no invite member info' do
      it 'does not show invite member info' do
        render

        expect(rendered).not_to have_content('Invite your team')
      end
    end

    context 'when experiment is enabled' do
      it 'shows invite members info', :aggregate_failures do
        render

        expect(rendered).to have_selector('[data-track-event=render]')
        expect(rendered).to have_selector('[data-track-label=invite_members_empty_project]', count: 2)
        expect(rendered).to have_content('Invite your team')
        expect(rendered).to have_content('Add members to this project and start collaborating with your team.')
        expect(rendered).to have_link('Invite members', href: project_project_members_path(project, sort: :access_level_desc))
        expect(rendered).to have_selector('[data-track-event=click_button]')
      end

      context 'when user does not have permissions to invite members' do
        let(:can_import_members) { false }

        it_behaves_like 'no invite member info'
      end
    end

    context 'when experiment is not enabled' do
      before do
        allow(view).to receive(:experiment_enabled?)
                         .with(:invite_members_empty_project_version_a).and_return(false)
      end

      it_behaves_like 'no invite member info'
    end
  end
end
