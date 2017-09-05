require 'spec_helper'

describe Projects::BranchesController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'branches-project') }

  render_views

  before(:all) do
    clean_frontend_fixtures('branches/')
  end

  before do
    sign_in(admin)
  end

  after do
    remove_repository(project)
  end

  it 'branches/new_branch.html.raw' do |example|
    get :new,
      namespace_id: project.namespace.to_param,
      project_id: project

    expect(response).to be_success
    store_frontend_fixture(response, example.description)
  end
end
