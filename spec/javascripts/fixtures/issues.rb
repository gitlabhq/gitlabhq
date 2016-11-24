require 'spec_helper'

describe Projects::IssuesController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:project) { create(:project_empty_repo) }

  render_views

  before(:all) do
    clean_frontend_fixtures('issues/')
  end

  before(:each) do
    sign_in(admin)
  end

  it 'issues/open-issue.html.raw' do |example|
    render_issue(example.description, create(:issue, project: project))
  end

  it 'issues/closed-issue.html.raw' do |example|
    render_issue(example.description, create(:closed_issue, project: project))
  end

  it 'issues/issue-with-task-list.html.raw' do |example|
    issue = create(:issue, project: project)
    issue.update(description: '- [ ] Task List Item')
    render_issue(example.description, issue)
  end

  private

  def render_issue(fixture_file_name, issue)
    get :show,
      namespace_id: project.namespace.to_param,
      project_id: project.to_param,
      id: issue.to_param

    expect(response).to be_success
    store_frontend_fixture(response, fixture_file_name)
  end
end
