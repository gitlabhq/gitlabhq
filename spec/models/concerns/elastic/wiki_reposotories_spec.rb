require 'spec_helper'

describe ProjectWiki, elastic: true do
  before do
    stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    Gitlab::Elastic::Helper.create_empty_index
  end

  after do
    Gitlab::Elastic::Helper.delete_index
    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  it "searches wiki page" do
    project = create :empty_project

    project.wiki.create_page("index_page", "Bla bla")

    project.wiki.index_blobs

    Gitlab::Elastic::Helper.refresh_index

    expect(project.wiki.search('bla', type: :blob)[:blobs][:total_count]).to eq(1)
  end
end
