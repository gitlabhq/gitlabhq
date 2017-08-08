require 'spec_helper'

describe Projects::BlobController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'branches-project') }

  render_views

  before(:all) do
    clean_frontend_fixtures('blob/')
  end

  before(:each) do
    sign_in(admin)
  end

  it 'blob/show.html.raw' do |example|
    get(:show,
        namespace_id: project.namespace,
        project_id: project,
        id: 'add-ipython-files/files/ipython/basic.ipynb')

    expect(response).to be_success
    store_frontend_fixture(response, example.description)
  end
end
