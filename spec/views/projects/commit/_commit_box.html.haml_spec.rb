# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/commit/_commit_box.html.haml' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    assign(:project, project)
    assign(:commit, project.commit)
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:can_collaborate_with_project?).and_return(false)
    project.add_developer(user)
  end

  it 'shows the commit SHA' do
    render

    expect(rendered).to have_text("#{Commit.truncate_sha(project.commit.sha)}")
  end

  context 'when there is a pipeline present' do
    context 'when pipeline has stages' do
      before do
        pipeline = create(:ci_pipeline, project: project, sha: project.commit.id, status: 'success')
        create(:ci_build, pipeline: pipeline, stage: 'build')

        assign(:last_pipeline, project.commit.last_pipeline)
      end

      it 'shows pipeline stages in vue' do
        render

        expect(rendered).to have_selector('.js-commit-pipeline-mini-graph')
      end
    end

    context 'when there are multiple pipelines for a commit' do
      it 'shows the last pipeline' do
        create(:ci_pipeline, project: project, sha: project.commit.id, status: 'success')
        create(:ci_pipeline, project: project, sha: project.commit.id, status: 'canceled')
        third_pipeline = create(:ci_pipeline, project: project, sha: project.commit.id, status: 'failed')

        assign(:last_pipeline, third_pipeline)

        render

        expect(rendered).to have_text("Pipeline ##{third_pipeline.id} failed")
      end
    end

    context 'when pipeline for the commit is blocked' do
      let!(:pipeline) do
        create(:ci_pipeline, :blocked, project: project,
                                       sha: project.commit.id)
      end

      it 'shows correct pipeline description' do
        assign(:last_pipeline, pipeline)

        render

        expect(rendered).to have_text "Pipeline ##{pipeline.id} " \
                                      'waiting for manual action'
      end
    end
  end
end
