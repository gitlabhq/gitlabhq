# frozen_string_literal: true

require 'spec_helper'

describe 'projects/tree/show' do
  include Devise::Test::ControllerHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:ref) { 'master' }
  let(:commit) { repository.commit(ref) }
  let(:path) { '' }
  let(:tree) { repository.tree(commit.id, path) }

  before do
    assign(:project, project)
    assign(:repository, repository)
    assign(:lfs_blob_ids, [])

    allow(view).to receive(:can?).and_return(true)
    allow(view).to receive(:can_collaborate_with_project?).and_return(true)
    allow(view).to receive_message_chain('user_access.can_push_to_branch?').and_return(true)
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
    allow(view).to receive(:current_user).and_return(project.creator)

    assign(:id, File.join(ref, path))
    assign(:ref, ref)
    assign(:path, path)
    assign(:last_commit, commit)
    assign(:tree, tree)
  end

  context 'for branch names ending on .json' do
    let(:ref) { 'ends-with.json' }

    it 'displays correctly' do
      render

      expect(rendered).to have_css('.js-project-refs-dropdown .dropdown-toggle-text', text: ref)
    end
  end

  context 'commit signatures' do
    context 'with vue tree view disabled' do
      before do
        stub_feature_flags(vue_file_list: false)
      end

      it 'rendered via js-signature-container' do
        render

        expect(rendered).to have_css('.js-signature-container')
      end
    end

    context 'with vue tree view enabled' do
      it 'are not rendered via js-signature-container' do
        render

        expect(rendered).not_to have_css('.js-signature-container')
      end
    end
  end
end
