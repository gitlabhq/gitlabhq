require 'spec_helper'

describe Issue, elastic: true do
  before do
    stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    described_class.__elasticsearch__.create_index!
  end

  after do
    described_class.__elasticsearch__.delete_index!
    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  it "searches issues" do
    project = create :empty_project

    create :issue, title: 'bla-bla term', project: project
    create :issue, description: 'bla-bla term', project: project
    create :issue, project: project

    # The issue I have no access to
    create :issue, title: 'bla-bla term'

    described_class.__elasticsearch__.refresh_index!

    options = { project_ids: [project.id] }

    expect(described_class.elastic_search('term', options: options).total_count).to eq(2)
  end

  it "returns json with all needed elements" do
    project = create :empty_project
    issue = create :issue, project: project

    expected_hash = issue.attributes.extract!('id', 'iid', 'title', 'description', 'created_at',
                                                'updated_at', 'state', 'project_id', 'author_id',
                                                'assignee_id', 'confidential')

    expected_hash['project'] = { "id" => project.id }
    expected_hash['author'] = { "id" => issue.author_id }
    expected_hash['updated_at_sort'] = issue.updated_at

    expect(issue.as_indexed_json).to eq(expected_hash)
  end
end
