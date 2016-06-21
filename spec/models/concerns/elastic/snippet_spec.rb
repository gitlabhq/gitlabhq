require 'spec_helper'

describe Snippet, elastic: true do
  before do
    stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    described_class.__elasticsearch__.create_index!
  end

  after do
    described_class.__elasticsearch__.delete_index!
    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  it "searches snippets by code" do
    user = create :user

    snippet = create :personal_snippet, :private, content: 'genius code', author: user
    create :personal_snippet, :private, content: 'genius code'
    create :personal_snippet, :private

    snippet3 = create :personal_snippet, :public, content: 'genius code'

    described_class.__elasticsearch__.refresh_index!

    options = { author_id: user.id }

    result = described_class.elastic_search_code('genius code', options: options)

    expect(result.total_count).to eq(2)
    expect(result.records.map(&:id)).to include(snippet.id, snippet3.id)
  end

  it "searches snippets by title and file_name" do
    user = create :user

    create :snippet, :public, title: 'home'
    create :snippet, :private, title: 'home 1'
    create :snippet, :public, file_name: 'index.php'
    create :snippet

    described_class.__elasticsearch__.refresh_index!

    options = { author_id: user.id }

    expect(described_class.elastic_search('home', options: options).total_count).to eq(1)
    expect(described_class.elastic_search('index.php', options:  options).total_count).to eq(1)
  end

  it "returns json with all needed elements" do
    snippet = create :project_snippet

    expected_hash =  snippet.attributes.extract!(
      'id',
      'title',
      'file_name',
      'content',
      'created_at',
      'updated_at',
      'state',
      'project_id',
      'author_id',
      'visibility_level'
    )

    expect(snippet.as_indexed_json).to eq(expected_hash)
  end
end
