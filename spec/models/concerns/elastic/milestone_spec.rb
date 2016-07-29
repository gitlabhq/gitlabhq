require 'spec_helper'

describe Milestone, elastic: true do
  before do
    stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    described_class.__elasticsearch__.create_index!
  end

  after do
    described_class.__elasticsearch__.delete_index!
    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  it "searches milestones" do
    project = create :empty_project

    create :milestone, title: 'bla-bla term', project: project
    create :milestone, description: 'bla-bla term', project: project
    create :milestone, project: project

    # The milestone you have no access to
    create :milestone, title: 'bla-bla term'

    described_class.__elasticsearch__.refresh_index!

    options = { project_ids: [project.id] }

    expect(described_class.elastic_search('term', options: options).total_count).to eq(2)
  end

  it "returns json with all needed elements" do
    milestone = create :milestone

    expected_hash = milestone.attributes.extract!(
      'id',
      'title',
      'description',
      'project_id',
      'created_at'
    )

    expected_hash[:updated_at_sort] = milestone.updated_at

    expect(milestone.as_indexed_json).to eq(expected_hash)
  end
end
