require 'spec_helper'

describe Projects::EnvironmentsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project_empty_repo, namespace: namespace, path: 'environments-project') }
  let(:environment) { create(:environment, name: 'production', project: project) }

  render_views

  before(:all) do
    clean_frontend_fixtures('environments/metrics')
  end

  before(:each) do
    sign_in(admin)
  end

  it 'environments/metrics/metrics.html.raw' do |example|
    get :metrics,
      namespace_id: project.namespace,
      project_id: project,
      id: environment.id

    expect(response).to be_success
    store_frontend_fixture(response, example.description)
  end
end
