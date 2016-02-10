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

    options = { projects_ids: [issue.project.id] }

    expect(Note.elastic_search('term', options: options).total_count).to eq(1)
  end
end
