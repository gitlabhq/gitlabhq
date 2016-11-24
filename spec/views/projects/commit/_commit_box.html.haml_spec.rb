require 'spec_helper'

describe 'projects/commit/_commit_box.html.haml' do
  include Devise::Test::ControllerHelpers

  let(:project) { create(:project) }

  before do
    assign(:project, project)
    assign(:commit, project.commit)
  end

  it 'shows the commit SHA' do
    render

    expect(rendered).to have_text("Commit #{Commit.truncate_sha(project.commit.sha)}")
  end

  it 'shows the last pipeline that ran for the commit' do
    create(:ci_pipeline, project: project, sha: project.commit.id, status: 'success')
    create(:ci_pipeline, project: project, sha: project.commit.id, status: 'canceled')
    third_pipeline = create(:ci_pipeline, project: project, sha: project.commit.id, status: 'failed')

    render

    expect(rendered).to have_text("Pipeline ##{third_pipeline.id} for #{Commit.truncate_sha(project.commit.sha)} failed")
  end
end
