require 'spec_helper'

describe ProjectsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, namespace: namespace, path: 'builds-project') }

  render_views

  before(:all) do
    clean_frontend_fixtures('projects/')
  end

  before(:each) do
    sign_in(admin)
  end

  it 'projects/dashboard.html.raw' do |example|
    get :show,
      namespace_id: project.namespace.to_param,
      id: project.to_param

    expect(response).to be_success
    store_frontend_fixture(response, example.description)
  end
end
