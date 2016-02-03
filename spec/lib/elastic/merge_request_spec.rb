require 'spec_helper'

describe "MergeRequest", elastic: true do
  before do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(true)
    MergeRequest.__elasticsearch__.create_index!
  end

  after do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(false)
    MergeRequest.__elasticsearch__.delete_index!
  end

  it "searches merge requests" do
    project = create :project

    create :merge_request, title: 'bla-bla term', source_project: project
    create :merge_request, description: 'term in description', source_project: project, target_branch: "feature2"
    create :merge_request, source_project: project, target_branch: "feature3"

    # The merge request you have no access to
    create :merge_request, title: 'also with term'

    MergeRequest.__elasticsearch__.refresh_index!

    options = { projects_ids: [project.id] }

    expect(MergeRequest.elastic_search('term', options: options).total_count).to eq(2)
  end
end
