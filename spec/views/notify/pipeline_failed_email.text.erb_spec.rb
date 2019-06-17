# frozen_string_literal: true
require 'spec_helper'

describe 'notify/pipeline_failed_email.text.erb' do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user, developer_projects: [project]) }
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, :simple, source_project: project) }

  let(:pipeline) do
    create(:ci_pipeline,
           :failed,
           project: project,
           user: user,
           ref: project.default_branch,
           sha: project.commit.sha)
  end

  before do
    assign(:project, project)
    assign(:pipeline, pipeline)
    assign(:merge_request, merge_request)
  end

  it 'renders the email correctly' do
    job = create(:ci_build, :failed, pipeline: pipeline, project: pipeline.project)

    render

    expect(rendered).to have_content('Your pipeline has failed')
    expect(rendered).to have_content(pipeline.project.name)
    expect(rendered).to have_content(pipeline.git_commit_message.truncate(50).gsub!(/\s+/, ' '))
    expect(rendered).to have_content(pipeline.commit.author_name)
    expect(rendered).to have_content("##{pipeline.id}")
    expect(rendered).to have_content(pipeline.user.name)
    expect(rendered).to have_content("/-/jobs/#{job.id}/raw")
  end
end
