require 'spec_helper'

describe Projects::BoardsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'boards-project') }

  render_views

  before(:all) do
    clean_frontend_fixtures('boards/')
  end

  before do
    sign_in(admin)
  end

  it 'boards/show.html' do
    get(:index, params: {
      namespace_id: project.namespace,
      project_id: project
    })

    expect(response).to be_successful
  end
end
