require 'spec_helper'

describe Note, elastic: true do
  before do
    stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    described_class.__elasticsearch__.create_index!
  end

  after do
    described_class.__elasticsearch__.delete_index!
    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  it "searches notes" do
    issue = create :issue

    create :note, note: 'bla-bla term', project: issue.project
    create :note, project: issue.project

    # The note in the project you have no access to
    create :note, note: 'bla-bla term'

    described_class.__elasticsearch__.refresh_index!

    options = { project_ids: [issue.project.id] }

    expect(described_class.elastic_search('term', options: options).total_count).to eq(1)
  end

  it "returns json with all needed elements" do
    note = create :note

    expected_hash_keys = [
      'id',
      'note',
      'project_id',
      'created_at',
      'issue',
      'updated_at_sort'
    ]

    expect(note.as_indexed_json.keys).to eq(expected_hash_keys)
  end

  it "does not create ElasticIndexerWorker job for system messages" do
    project = create :project
    issue = create :issue, project: project

    # Only issue should be updated
    expect(ElasticIndexerWorker).to receive(:perform_async).with(:update, 'Issue', anything, anything)
    create :note, :system, project: project, noteable: issue
  end

  context 'notes to confidential issues' do
    it "does not find note" do
      issue = create :issue, :confidential

      create :note, note: 'bla-bla term', project: issue.project, noteable: issue
      create :note, project: issue.project, noteable: issue

      Note.__elasticsearch__.refresh_index!

      options = { project_ids: [issue.project.id] }

      expect(Note.elastic_search('term', options: options).total_count).to eq(0)
    end

    it "finds note when user is authorized to see it" do
      user = create :user
      issue = create :issue, :confidential, author: user

      create :note, note: 'bla-bla term', project: issue.project, noteable: issue
      create :note, project: issue.project, noteable: issue

      Note.__elasticsearch__.refresh_index!

      options = { project_ids: [issue.project.id], current_user: user }

      expect(Note.elastic_search('term', options: options).total_count).to eq(1)
    end

    it "return notes with matching content for project members" do
      user = create :user
      issue = create :issue, :confidential, author: user

      member = create(:user)
      issue.project.team << [member, :developer]

      create :note, note: 'bla-bla term', project: issue.project, noteable: issue
      create :note, project: issue.project, noteable: issue

      Note.__elasticsearch__.refresh_index!

      options = { project_ids: [issue.project.id], current_user: member }

      expect(Note.elastic_search('term', options: options).total_count).to eq(1)
    end

    it "does not return notes with matching content for project members with guest role" do
      user = create :user
      issue = create :issue, :confidential, author: user

      member = create(:user)
      issue.project.team << [member, :guest]

      create :note, note: 'bla-bla term', project: issue.project, noteable: issue
      create :note, project: issue.project, noteable: issue

      Note.__elasticsearch__.refresh_index!

      options = { project_ids: [issue.project.id], current_user: member }

      expect(Note.elastic_search('term', options: options).total_count).to eq(0)
    end
  end
end
