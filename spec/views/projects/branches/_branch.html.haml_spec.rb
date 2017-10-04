require 'spec_helper'

describe 'projects/branches/_branch.html.haml' do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:branch) { repository.find_branch('branch-merged') }

  before do
    assign(:max_commits, 0)
    assign(:project, project)
    assign(:repository, repository)
    assign(:refs_pipelines, {})

    allow(view).to receive(:branch).and_return(branch)
    allow(repository).to receive(:merged_to_root_ref?).and_return(true)
    allow(repository.root_branch.dereferenced_target)
      .to receive(:committed_date)
      .and_return(Date.new(2000, 1, 10))

    view.extend(Gitlab::Allowable)
  end

  context 'when the branch was not updated for more than 1 year' do
    before do
      allow(branch.dereferenced_target)
        .to receive(:committed_date)
        .and_return(Date.new(1999, 1, 1))
    end

    it 'shows stale' do
      render

      expect(rendered).to have_text('stale')
    end

    it 'does not try to call Repository#merged_to_root_ref' do
      render

      expect(repository).not_to have_received(:merged_to_root_ref?)
    end
  end

  context 'when the branch was updated yesterday' do
    before do
      allow(branch.dereferenced_target)
        .to receive(:committed_date)
        .and_return(Date.new(2000, 1, 9))
    end

    it 'shows merged' do
      render

      expect(rendered).to have_text('merged')
    end
  end
end
