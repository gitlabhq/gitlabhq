require 'spec_helper'

describe Network::Graph, models: true do
  let(:project) { create(:project, :repository) }
  let!(:note_on_commit) { create(:note_on_commit, project: project) }

  it '#initialize' do
    graph = described_class.new(project, 'refs/heads/master', project.repository.commit, nil)

    expect(graph.notes).to eq( { note_on_commit.commit_id => 1 } )
  end

  describe "#commits" do
    let(:graph) { described_class.new(project, 'refs/heads/master', project.repository.commit, nil) }

    it "returns a list of commits" do
      commits = graph.commits

      expect(commits).not_to be_empty
      expect(commits).to all( be_kind_of(Network::Commit) )
    end

    it "sorts the commits by commit date (descending)" do
      # Remove duplicate timestamps because they make it harder to
      # assert that the commits are sorted as expected.
      commits = graph.commits.uniq(&:date)
      sorted_commits = commits.sort_by(&:date).reverse

      expect(commits).not_to be_empty
      expect(commits.map(&:id)).to eq(sorted_commits.map(&:id))
    end
  end
end
