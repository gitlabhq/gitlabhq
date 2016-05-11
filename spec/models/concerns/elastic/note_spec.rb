require 'spec_helper'

describe "Note", elastic: true do
  before do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(true)
    Note.__elasticsearch__.create_index!
  end

  after do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(false)
    Note.__elasticsearch__.delete_index!
  end

  it "searches notes" do
    issue = create :issue

    create :note, note: 'bla-bla term', project: issue.project
    create :note, project: issue.project

    # The note in the project you have no access to
    create :note, note: 'bla-bla term'

    Note.__elasticsearch__.refresh_index!

    options = { project_ids: [issue.project.id] }

    expect(Note.elastic_search('term', options: options).total_count).to eq(1)
  end

  it "returns json with all needed elements" do
    note = create :note

    expected_hash =  note.attributes.extract!(
      'id',
      'note',
      'project_id',
      'created_at'
    )

    expected_hash['updated_at_sort'] = note.updated_at

    expect(note.as_indexed_json).to eq(expected_hash)
  end

  it "does not create ElasticIndexerWorker job for award or system messages" do
    project = create :empty_project
    expect(ElasticIndexerWorker).to_not receive(:perform_async)
    create :note, :system, project: project
    create :note, :award, project: project
  end
end
