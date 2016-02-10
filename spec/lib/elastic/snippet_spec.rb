require 'spec_helper'

describe "Snippet", elastic: true do
  before do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(true)
    Snippet.__elasticsearch__.create_index!
  end

  after do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(false)
    Snippet.__elasticsearch__.delete_index!
  end

  it "searches snippets by code" do
    @snippet = create :personal_snippet, content: 'genius code'
    @snippet1 = create :personal_snippet

    # the snippet I have no access to
    @snippet2 = create :personal_snippet, content: 'genius code'

    @snippet_ids = [@snippet.id, @snippet1.id]

    Snippet.__elasticsearch__.refresh_index!

    options = { ids: @snippet_ids }

    expect(Snippet.elastic_search_code('genius code', options: options).total_count).to eq(1)
  end

  it "searches snippets by title and file_name" do
    @snippet = create :snippet, title: 'home'
    @snippet1 = create :snippet, file_name: 'index.php'
    @snippet2 = create :snippet

    # the snippet I have no access to
    @snippet3 = create :snippet, title: 'home'

    @snippet_ids = [@snippet.id, @snippet1.id, @snippet2.id]
    
    Snippet.__elasticsearch__.refresh_index!

    options = { ids: @snippet_ids }

    expect(Snippet.elastic_search('home', options: options).total_count).to eq(1)
    expect(Snippet.elastic_search('index.php', options:  options).total_count).to eq(1)
  end
end
