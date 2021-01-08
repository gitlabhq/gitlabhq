# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'notify/pipeline_failed_email.text.erb' do
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

  shared_examples_for 'renders the pipeline failed email correctly' do
    it 'renders the email correctly' do
      render

      expect(rendered).to have_content("Pipeline ##{pipeline.id} has failed!")
      expect(rendered).to have_content(pipeline.project.name)
      expect(rendered).to have_content(pipeline.git_commit_message.truncate(50).gsub(/\s+/, ' '))
      expect(rendered).to have_content(pipeline.commit.author_name)
      expect(rendered).to have_content("##{pipeline.id}")
      expect(rendered).to have_content(pipeline.user.name)
      expect(rendered).to have_content(build.id)
    end

    it_behaves_like 'correct pipeline information for pipelines for merge requests'
  end

  context 'when the pipeline contains a failed job' do
    let!(:build) { create(:ci_build, :failed, pipeline: pipeline, project: pipeline.project) }

    it_behaves_like 'renders the pipeline failed email correctly'
  end

  context 'when the latest failed job is a bridge job' do
    let!(:build) { create(:ci_bridge, status: :failed, pipeline: pipeline, project: pipeline.project) }

    it_behaves_like 'renders the pipeline failed email correctly'
  end
end
