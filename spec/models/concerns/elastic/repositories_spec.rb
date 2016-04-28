require 'spec_helper'

describe "Repository", elastic: true do
  before do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(true)
    Repository.__elasticsearch__.create_index!
  end

  after do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(false)
    Repository.__elasticsearch__.delete_index!
  end

  it "searches blobs and commits" do
    project = create :project

    project.repository.index_blobs
    project.repository.index_commits
    
    Repository.__elasticsearch__.refresh_index!

    expect(project.repository.search('def popen')[:blobs][:total_count]).to eq(1)
    expect(project.repository.search('initial')[:commits][:total_count]).to eq(1)
  end
end
