require 'spec_helper'

describe Repository, elastic: true do
  before do
    stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    Gitlab::Elastic::Helper.create_empty_index
  end

  after do
    Gitlab::Elastic::Helper.delete_index
    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  it "searches blobs and commits" do
    project = create :project

    project.repository.index_blobs
    project.repository.index_commits

    Gitlab::Elastic::Helper.refresh_index

    expect(project.repository.search('def popen')[:blobs][:total_count]).to eq(1)
    expect(project.repository.search('initial')[:commits][:total_count]).to eq(1)
  end
end
