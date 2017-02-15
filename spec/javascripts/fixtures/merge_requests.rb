require 'spec_helper'

describe Projects::MergeRequestsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, namespace: namespace, path: 'merge-requests-project') }

  render_views

  before(:all) do
    clean_frontend_fixtures('merge_requests/')
  end

  before(:each) do
    sign_in(admin)
  end

  it 'merge_requests/merge_request_with_task_list.html.raw' do |example|
    merge_request = create(:merge_request, :with_diffs, source_project: project, target_project: project, description: '- [ ] Task List Item')
    render_merge_request(example.description, merge_request)
  end

  private

  def render_merge_request(fixture_file_name, merge_request)
    get :show,
      namespace_id: project.namespace.to_param,
      project_id: project.to_param,
      id: merge_request.to_param

    expect(response).to be_success
    store_frontend_fixture(response, fixture_file_name)
  end
end
