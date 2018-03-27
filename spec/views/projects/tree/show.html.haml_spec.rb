require 'spec_helper'

describe 'projects/tree/show' do
  include Devise::Test::ControllerHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  before do
    assign(:project, project)
    assign(:repository, repository)
    assign(:lfs_blob_ids, [])

    allow(view).to receive(:can?).and_return(true)
    allow(view).to receive(:can_collaborate_with_project?).and_return(true)
    allow(view).to receive_message_chain('user_access.can_push_to_branch?').and_return(true)
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
  end

  context 'for branch names ending on .json' do
    let(:ref) { 'ends-with.json' }
    let(:commit) { repository.commit(ref) }
    let(:path) { '' }
    let(:tree) { repository.tree(commit.id, path) }

    before do
      assign(:id, File.join(ref, path))
      assign(:ref, ref)
      assign(:path, path)
      assign(:last_commit, commit)
      assign(:tree, tree)
    end

    it 'displays correctly' do
      render
      expect(rendered).to have_css('.js-project-refs-dropdown .dropdown-toggle-text', text: ref)
      expect(rendered).to have_css('.readme-holder')
    end
  end
end
