require 'spec_helper'

describe "Milestone", elastic: true do
  before do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(true)
    Milestone.__elasticsearch__.create_index!
  end

  after do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(false)
    Milestone.__elasticsearch__.delete_index!
  end

  it "searches milestones" do
    project = create :empty_project

    create :milestone, title: 'bla-bla term', project: project
    create :milestone, description: 'bla-bla term', project: project
    create :milestone, project: project

    create :milestone, title: 'bla-bla term'

    Milestone.__elasticsearch__.refresh_index!

    options = { projects_ids: [project.id] }

    expect(Milestone.elastic_search('term', options: options).total_count).to eq(2)
  end
end
