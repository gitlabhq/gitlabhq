require 'spec_helper'

describe "ProjectWiki", elastic: true do
  before do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(true)
    ProjectWiki.__elasticsearch__.create_index!
  end

  after do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(false)
    ProjectWiki.__elasticsearch__.delete_index!
  end

  it "searches wiki page" do
    project = create :empty_project

    project.wiki.create_page("index_page", "Bla bla")

    project.wiki.index_blobs
    
    ProjectWiki.__elasticsearch__.refresh_index!

    expect(project.wiki.search('bla', type: :blob)[:blobs][:total_count]).to eq(1)
  end
end
