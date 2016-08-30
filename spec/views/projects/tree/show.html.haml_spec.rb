require 'spec_helper'

describe 'projects/tree/show' do
  include Devise::TestHelpers

  let(:project) { create(:project) }
  let(:repository) { project.repository }

  before do
    assign(:project, project)
    assign(:repository, repository)

    allow(view).to receive(:can?).and_return(true)
    allow(view).to receive(:can_collaborate_with_project?).and_return(true)
  end

  context 'for branch names ending on .json' do
    let(:ref) { 'ends-with.json' }
    let(:commit) { repository.commit(ref) }
    let(:path) { '' }
    let(:tree) { repository.tree(commit.id, path) }

    before do
      assign(:ref, ref)
      assign(:commit, commit)
      assign(:id, commit.id)
      assign(:tree, tree)
      assign(:path, path)
    end

    it 'displays correctly' do
      render
      expect(rendered).to have_css('.js-project-refs-dropdown .dropdown-toggle-text', text: ref)
      expect(rendered).to have_css('.readme-holder .file-content', text: ref)
    end
  end
end
