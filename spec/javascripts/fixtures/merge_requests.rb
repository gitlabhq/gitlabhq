require 'spec_helper'

describe Projects::MergeRequestsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'merge-requests-project') }
  let(:merge_request) { create(:merge_request, :with_diffs, source_project: project, target_project: project, description: '- [ ] Task List Item') }
  let(:merged_merge_request) { create(:merge_request, :merged, source_project: project, target_project: project) }
  let(:pipeline) do
    create(
      :ci_pipeline,
      project: merge_request.source_project,
      ref: merge_request.source_branch,
      sha: merge_request.diff_head_sha
    )
  end
  let(:path) { "files/ruby/popen.rb" }
  let(:position) do
    Gitlab::Diff::Position.new(
      old_path: path,
      new_path: path,
      old_line: nil,
      new_line: 14,
      diff_refs: merge_request.diff_refs
    )
  end

  render_views

  before(:all) do
    clean_frontend_fixtures('merge_requests/')
  end

  before do
    sign_in(admin)
  end

  after do
    remove_repository(project)
  end

  it 'merge_requests/merge_request_of_current_user.html.raw' do |example|
    merge_request.update(author: admin)

    render_merge_request(example.description, merge_request)
  end

  it 'merge_requests/merge_request_with_task_list.html.raw' do |example|
    create(:ci_build, :pending, pipeline: pipeline)

    render_merge_request(example.description, merge_request)
  end

  it 'merge_requests/merged_merge_request.html.raw' do |example|
    allow_any_instance_of(MergeRequest).to receive(:source_branch_exists?).and_return(true)
    allow_any_instance_of(MergeRequest).to receive(:can_remove_source_branch?).and_return(true)
    render_merge_request(example.description, merged_merge_request)
  end

  it 'merge_requests/diff_comment.html.raw' do |example|
    create(:diff_note_on_merge_request, project: project, author: admin, position: position, noteable: merge_request)
    create(:note_on_merge_request, author: admin, project: project, noteable: merge_request)
    render_merge_request(example.description, merge_request)
  end

  it 'merge_requests/merge_request_with_comment.html.raw' do |example|
    create(:note_on_merge_request, author: admin, project: project, noteable: merge_request, note: '- [ ] Task List Item')
    render_merge_request(example.description, merge_request)
  end

  it 'merge_requests/discussions.json' do |example|
    create(:diff_note_on_merge_request, project: project, author: admin, position: position, noteable: merge_request)
    render_discussions_json(merge_request, example.description)
  end

  it 'merge_requests/diff_discussion.json' do |example|
    create(:diff_note_on_merge_request, project: project, author: admin, position: position, noteable: merge_request)
    render_discussions_json(merge_request, example.description)
  end

  context 'with image diff' do
    let(:merge_request2) { create(:merge_request_with_diffs, :with_image_diffs, source_project: project, title: "Added images") }
    let(:image_path) { "files/images/ee_repo_logo.png" }
    let(:image_position) do
      Gitlab::Diff::Position.new(
        old_path: image_path,
        new_path: image_path,
        width: 100,
        height: 100,
        x: 1,
        y: 1,
        position_type: "image",
        diff_refs: merge_request2.diff_refs
      )
    end

    it 'merge_requests/image_diff_discussion.json' do |example|
      create(:diff_note_on_merge_request, project: project, noteable: merge_request2, position: image_position)
      render_discussions_json(merge_request2, example.description)
    end
  end

  private

  def render_discussions_json(merge_request, fixture_file_name)
    get :discussions,
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: merge_request.to_param,
      format: :json

    store_frontend_fixture(response, fixture_file_name)
  end

  def render_merge_request(fixture_file_name, merge_request)
    get :show,
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: merge_request.to_param,
      format: :html

    expect(response).to be_success
    store_frontend_fixture(response, fixture_file_name)
  end
end
