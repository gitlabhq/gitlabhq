# frozen_string_literal: true

require 'spec_helper'

describe 'notify/pipeline_success_email.text.erb' do
  let(:user) { create(:user, developer_projects: [project]) }
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, :simple, source_project: project) }

  let(:pipeline) do
    create(:ci_pipeline,
           :success,
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

  it_behaves_like 'correct pipeline information for pipelines for merge requests'
end
