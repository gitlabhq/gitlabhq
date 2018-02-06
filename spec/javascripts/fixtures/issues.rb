require 'spec_helper'

describe Projects::IssuesController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project_empty_repo, namespace: namespace, path: 'issues-project') }

  render_views

  before(:all) do
    clean_frontend_fixtures('issues/')
  end

  before do
    sign_in(admin)
  end

  after do
    remove_repository(project)
  end

  it 'issues/open-issue.html.raw' do |example|
    render_issue(example.description, create(:issue, project: project))
  end

  it 'issues/closed-issue.html.raw' do |example|
    render_issue(example.description, create(:closed_issue, project: project))
  end

  it 'issues/issue-with-task-list.html.raw' do |example|
    issue = create(:issue, project: project, description: '- [ ] Task List Item')
    render_issue(example.description, issue)
  end

  it 'issues/issue_with_comment.html.raw' do |example|
    issue = create(:issue, project: project)
    create(:note, project: project, noteable: issue, note: '- [ ] Task List Item').save
    render_issue(example.description, issue)
  end

  it 'issues/issue_list.html.raw' do |example|
    create(:issue, project: project)

    get :index,
      namespace_id: project.namespace.to_param,
      project_id: project

    expect(response).to be_success
    store_frontend_fixture(response, example.description)
  end

  private

  def render_issue(fixture_file_name, issue)
    get :show,
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: issue.to_param

    expect(response).to be_success
    store_frontend_fixture(response, fixture_file_name)
  end
end
