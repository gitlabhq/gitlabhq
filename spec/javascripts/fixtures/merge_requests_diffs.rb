
require 'spec_helper'

describe Projects::MergeRequests::DiffsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'merge-requests-project') }
  let(:merge_request) { create(:merge_request, :with_diffs, source_project: project, target_project: project, description: '- [ ] Task List Item') }
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
    clean_frontend_fixtures('merge_request_diffs/')
  end

  before do
    sign_in(admin)
  end

  after do
    remove_repository(project)
  end

  it 'merge_request_diffs/inline_changes_tab_with_comments.json' do |example|
    create(:diff_note_on_merge_request, project: project, author: admin, position: position, noteable: merge_request)
    create(:note_on_merge_request, author: admin, project: project, noteable: merge_request)
    render_merge_request(example.description, merge_request)
  end

  it 'merge_request_diffs/parallel_changes_tab_with_comments.json' do |example|
    create(:diff_note_on_merge_request, project: project, author: admin, position: position, noteable: merge_request)
    create(:note_on_merge_request, author: admin, project: project, noteable: merge_request)
    render_merge_request(example.description, merge_request, view: 'parallel')
  end

  private

  def render_merge_request(fixture_file_name, merge_request, view: 'inline')
    get :show,
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: merge_request.to_param,
      format: :json,
      view: view

    expect(response).to be_success
    store_frontend_fixture(response, fixture_file_name)
  end
end
