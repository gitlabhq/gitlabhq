require 'spec_helper'

describe Network::Graph, models: true do
  let(:project) { create(:project) }
  let!(:note_on_commit) { create(:note_on_commit, project: project) }

  it '#initialize' do
    graph = described_class.new(project, 'refs/heads/master', project.repository.commit, nil)

    expect(graph.notes).to eq( { note_on_commit.commit_id => 1 } )
  end
end
