require 'spec_helper'

describe "Issue", elastic: true do
  before do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(true)
    Issue.__elasticsearch__.create_index!
  end

  after do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(false)
    Issue.__elasticsearch__.delete_index!
  end

  it "searches issues" do
    project = create :empty_project

    create :issue, title: 'bla-bla term', project: project
    create :issue, description: 'bla-bla term', project: project
    create :issue, project: project

    # The issue I have no access to
    create :issue, title: 'bla-bla term'

    Issue.__elasticsearch__.refresh_index!

    options = { projects_ids: [project.id] }

    expect(Issue.elastic_search('term', options: options).total_count).to eq(2)
  end
end
