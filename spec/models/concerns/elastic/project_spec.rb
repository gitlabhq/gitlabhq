require 'spec_helper'

describe Project, elastic: true do
  before do
    stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    described_class.__elasticsearch__.create_index!
  end

  after do
    described_class.__elasticsearch__.delete_index!
    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  it "searches projects" do
    project = create :empty_project, name: 'test'
    project1 = create :empty_project, path: 'test1'
    project2 = create :empty_project
    create :empty_project, path: 'someone_elses_project'
    project_ids = [project.id, project1.id, project2.id]

    described_class.__elasticsearch__.refresh_index!

    expect(described_class.elastic_search('test', options: { pids: project_ids }).total_count).to eq(1)
    expect(described_class.elastic_search('test1', options: { pids: project_ids }).total_count).to eq(1)
    expect(described_class.elastic_search('someone_elses_project', options: { pids: project_ids }).total_count).to eq(0)
  end

  it "returns json with all needed elements" do
    project = create :empty_project

    expected_hash = project.attributes.extract!(
      'id',
      'name',
      'path',
      'description',
      'namespace_id',
      'created_at',
      'archived',
      'visibility_level',
      'last_activity_at'
    )

    expected_hash['name_with_namespace'] = project.name_with_namespace
    expected_hash['path_with_namespace'] = project.path_with_namespace

    expect(project.as_indexed_json).to eq(expected_hash)
  end
end
