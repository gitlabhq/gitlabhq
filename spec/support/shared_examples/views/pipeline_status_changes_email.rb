# frozen_string_literal: true

RSpec.shared_examples 'pipeline status changes email' do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user, developer_of: project) }
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, :simple, source_project: project) }

  let(:pipeline) do
    create(
      :ci_pipeline,
      project: project,
      user: user,
      ref: project.default_branch,
      sha: project.commit.sha,
      status: status
    )
  end

  before do
    assign(:project, project)
    assign(:pipeline, pipeline)
    assign(:merge_request, merge_request)
  end

  shared_examples_for 'renders the pipeline status changes email correctly' do
    let(:pipeline_name_or_id) { pipeline.name || "##{pipeline.id}" }

    context 'pipeline with user' do
      it 'renders the email correctly' do
        render

        expect(rendered).to have_content title
        expect(rendered).to have_content pipeline.project.name
        expect(rendered).to have_content pipeline.git_commit_message.truncate(50).gsub(/\s+/, ' ')
        expect(rendered).to have_content pipeline.commit.author_name
        expect(rendered).to have_content pipeline_name_or_id
        expect(rendered).to have_content pipeline.user.name

        if status == :failed
          expect(rendered).to have_content build.name
          expect(rendered).to include("#{build.project.full_path}/-/jobs/#{build.id}") unless build.is_a?(Ci::Bridge)
        end
      end

      it_behaves_like 'correct pipeline information for pipelines for merge requests'
    end

    context 'pipeline without user' do
      before do
        pipeline.update_attribute(:user, nil)
      end

      it 'renders the email correctly' do
        render

        expect(rendered).to have_content title
        expect(rendered).to have_content pipeline.project.name
        expect(rendered).to have_content pipeline.git_commit_message.truncate(50).gsub(/\s+/, ' ')
        expect(rendered).to have_content pipeline.commit.author_name
        expect(rendered).to have_content pipeline_name_or_id
        expect(rendered).to have_content "by API"

        if status == :failed
          expect(rendered).to have_content build.name
          expect(rendered).to include("#{build.project.full_path}/-/jobs/#{build.id}") unless build.is_a?(Ci::Bridge)
        end
      end
    end
  end

  context 'when the pipeline contains a failed job' do
    let(:ci_stage) { create(:ci_stage, pipeline: pipeline) }
    let!(:build) do
      create(:ci_build, status: status, pipeline: pipeline, project: pipeline.project, ci_stage: ci_stage)
    end

    it_behaves_like 'renders the pipeline status changes email correctly'
  end

  context 'when the latest failed job is a bridge job' do
    let(:ci_stage) { create(:ci_stage, pipeline: pipeline) }
    let!(:build) do
      create(:ci_bridge, status: status, pipeline: pipeline, project: pipeline.project, ci_stage: ci_stage)
    end

    it_behaves_like 'renders the pipeline status changes email correctly'
  end
end
