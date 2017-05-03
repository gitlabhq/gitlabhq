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

    Sidekiq::Testing.inline! do
      project.wiki.create_page("index_page", "Bla bla term1")
      project.wiki.create_page("omega_page", "Bla bla term2")
      project.wiki.index_blobs

      Gitlab::Elastic::Helper.refresh_index
    end

    expect(project.wiki.search('term1', type: :blob)[:blobs][:total_count]).to eq(1)
    expect(project.wiki.search('term1 | term2', type: :blob)[:blobs][:total_count]).to eq(2)
  end
end
