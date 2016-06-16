require 'spec_helper'

describe ProjectWiki, elastic: true do
  before do
    stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    described_class.__elasticsearch__.create_index!
  end

  after do
    described_class.__elasticsearch__.delete_index!
    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  it "searches wiki page" do
    project = create :empty_project

    project.wiki.create_page("index_page", "Bla bla")

    project.wiki.index_blobs

    described_class.__elasticsearch__.refresh_index!

    expect(project.wiki.search('bla', type: :blob)[:blobs][:total_count]).to eq(1)
  end
end
