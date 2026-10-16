# frozen_string_literal: true

require 'spec_helper'

# Documents the cases where the MR widget is stuck on "Checking pipeline status.":
# widget.json has `has_ci: true` but cached_widget.json has no `pipeline`.
# See https://gitlab.com/gitlab-org/gitlab/-/work_items/598423
RSpec.describe 'MR widget pipeline status', :sidekiq_inline, :aggregate_failures, feature_category: :pipeline_composition do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :repository, maintainers: user) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  let(:mr_pipeline_config) do
    { test: { script: 'echo', rules: [{ if: '$CI_PIPELINE_SOURCE == "merge_request_event"' }] } }
  end

  let(:ci_config) { mr_pipeline_config }
  let(:commit_message) { 'New commit' }
  let(:refresh_params) { {} }

  before do
    stub_ci_pipeline_yaml_file(ci_config && YAML.dump(ci_config.deep_stringify_keys))
    sign_in(user)
  end

  def create_initial_mr_pipeline
    pipeline = create(:ci_pipeline, :success, :detached_merge_request_pipeline, merge_request: merge_request)
    merge_request.update_head_pipeline

    expect(merge_request.reload.diff_head_pipeline).to eq(pipeline)
  end

  def push_new_commit
    oldrev = merge_request.diff_head_sha
    newrev = project.repository.create_file(
      user, "file-#{SecureRandom.hex(4)}.txt", 'content',
      message: commit_message, branch_name: merge_request.source_branch
    )

    MergeRequests::RefreshService
      .new(project: project, current_user: user, params: refresh_params)
      .execute(oldrev, newrev, "refs/heads/#{merge_request.source_branch}")

    expect(merge_request.reload.diff_head_sha).to eq(newrev)

    newrev
  end

  def create_external_pipeline(sha:, ref:)
    response = Ci::CreateCommitStatusService
      .new(project, user, { sha: sha, state: 'success', name: 'external-ci', ref: ref })
      .execute(optional_commit_status_params: {})

    expect(response).to be_success
    expect(project.all_pipelines.where(sha: sha).pluck(:source, :ref)).to match_array([['external', ref]])
  end

  def widget_json
    get widget_project_json_merge_request_path(project, merge_request, format: :json)

    expect(response).to have_gitlab_http_status(:ok)
    json_response
  end

  def cached_widget_json
    get cached_widget_project_json_merge_request_path(project, merge_request, format: :json)

    expect(response).to have_gitlab_http_status(:ok)
    json_response
  end

  shared_examples 'stuck on checking pipeline status' do
    it 'reports CI but no pipeline for the latest commit' do
      expect(merge_request.reload.diff_head_pipeline).to be_nil
      expect(widget_json['has_ci']).to be(true)
      expect(cached_widget_json).not_to have_key('pipeline')
    end
  end

  context 'when the new commit creates an MR pipeline' do
    before do
      create_initial_mr_pipeline
      push_new_commit
    end

    it 'shows the new pipeline' do
      expect(merge_request.reload.diff_head_pipeline).to be_present
      expect(widget_json['has_ci']).to be(true)
      expect(cached_widget_json['pipeline']).to be_present
    end
  end

  context 'when workflow:rules filter out the new commit' do
    let(:commit_message) { 'no-pipeline' }
    let(:ci_config) do
      mr_pipeline_config.merge(
        workflow: { rules: [{ if: '$CI_COMMIT_MESSAGE =~ /no-pipeline/', when: 'never' }, { when: 'always' }] }
      )
    end

    before do
      create_initial_mr_pipeline
      push_new_commit
    end

    it_behaves_like 'stuck on checking pipeline status'
  end

  context 'when pipelines only run manually' do
    let(:ci_config) do
      mr_pipeline_config.merge(workflow: { rules: [{ if: '$CI_PIPELINE_SOURCE == "web"' }] })
    end

    before do
      create_initial_mr_pipeline
      push_new_commit
    end

    it_behaves_like 'stuck on checking pipeline status'
  end

  context 'when the new commit is pushed with a CI job token' do
    let(:refresh_params) { { gitaly_context: { 'glBuildId' => '123' } } }

    before do
      create_initial_mr_pipeline
      push_new_commit
    end

    it_behaves_like 'stuck on checking pipeline status'
  end

  context 'when the new commit is pushed with ci.skip and there is no CI config' do
    let(:ci_config) { nil }
    let(:refresh_params) { { push_options: { ci: { skip: true } } } }

    before do
      create_initial_mr_pipeline
      push_new_commit
    end

    it_behaves_like 'stuck on checking pipeline status'
  end

  context 'when skip branch pipelines for MRs is enabled and only an external pipeline exists' do
    # The job token push stops the MR pipeline, the setting hides the external one.
    let(:refresh_params) { { gitaly_context: { 'glBuildId' => '123' } } }

    before do
      project.ci_cd_settings.update!(skip_branch_pipelines_for_mrs: true)
      create_initial_mr_pipeline
      sha = push_new_commit

      create_external_pipeline(sha: sha, ref: merge_request.source_branch)
    end

    it_behaves_like 'stuck on checking pipeline status'
  end

  context 'when the project has a CI integration and no pipelines' do
    let(:ci_config) { nil }

    before do
      create(:jenkins_integration, project: project)
    end

    it_behaves_like 'stuck on checking pipeline status'

    context 'when the external status is posted on another ref' do
      before do
        create_external_pipeline(sha: merge_request.diff_head_sha, ref: merge_request.target_branch)
      end

      it_behaves_like 'stuck on checking pipeline status'
    end
  end

  context 'when the user cannot read pipelines' do
    let_it_be_with_reload(:project) { create(:project, :repository, :public, public_builds: false) }

    before do
      create_initial_mr_pipeline
      sign_out(user)
    end

    it 'reports CI but no pipeline' do
      expect(merge_request.reload.diff_head_pipeline).to be_present
      expect(widget_json['has_ci']).to be(true)
      expect(cached_widget_json).not_to have_key('pipeline')
    end
  end
end
