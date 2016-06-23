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

  it 'searches snippets by code' do
    author = create(:user)
    project = create(:project)

    public_snippet   = create(:snippet, :public, content: 'password: XXX')
    internal_snippet = create(:snippet, :internal, content: 'password: XXX')
    private_snippet  = create(:snippet, :private, content: 'password: XXX', author: author)

    project_public_snippet   = create(:snippet, :public, project: project, content: 'password: XXX')
    project_internal_snippet = create(:snippet, :internal, project: project, content: 'password: XXX')
    project_private_snippet  = create(:snippet, :private, project: project, content: 'password: XXX')

    described_class.__elasticsearch__.refresh_index!

    # returns only public snippets when user is blank
    result = described_class.elastic_search_code('password', options: { user: nil })
    expect(result.total_count).to eq(2)
    expect(result.records).to match_array [public_snippet, project_public_snippet]

    # returns only public, and internal snippets for regular users
    regular_user = create(:user)
    result = described_class.elastic_search_code('password', options: { user: regular_user })
    expect(result.total_count).to eq(4)
    expect(result.records).to match_array [public_snippet, internal_snippet, project_public_snippet, project_internal_snippet]

    # returns public, internal snippets and project private snippets for project members
    member = create(:user)
    project.team << [member, :developer]
    result = described_class.elastic_search_code('password', options: { user: member })
    expect(result.total_count).to eq(5)
    expect(result.records).to match_array [public_snippet, internal_snippet, project_public_snippet, project_internal_snippet, project_private_snippet]

    # returns private snippets where the user is the author
    result = described_class.elastic_search_code('password', options: { user: author })
    expect(result.total_count).to eq(5)
    expect(result.records).to match_array [public_snippet, internal_snippet, private_snippet, project_public_snippet, project_internal_snippet]

    # returns all snippets when for admins
    admin = create(:admin)
    result = described_class.elastic_search_code('password', options: { user: admin })
    expect(result.total_count).to eq(6)
    expect(result.records).to match_array [public_snippet, internal_snippet, private_snippet, project_public_snippet, project_internal_snippet, project_private_snippet]
  end

  it 'searches snippets by title and file_name' do
    user = create :user

    create(:snippet, :public, title: 'home')
    create(:snippet, :private, title: 'home 1')
    create(:snippet, :public, file_name: 'index.php')
    create(:snippet)

    described_class.__elasticsearch__.refresh_index!

    options = { user: user }

    expect(described_class.elastic_search('home', options: options).total_count).to eq(1)
    expect(described_class.elastic_search('index.php', options:  options).total_count).to eq(1)
  end

  it 'returns json with all needed elements' do
    snippet = create(:project_snippet)

    expected_hash = snippet.attributes.extract!(
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
