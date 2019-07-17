require 'spec_helper'

describe Projects::CommitController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  set(:project)  { create(:project, :repository) }
  set(:user)     { create(:user) }
  let(:commit)   { project.commit("master") }

  render_views

  before(:all) do
    clean_frontend_fixtures('commit/')
  end

  before do
    project.add_maintainer(user)
    sign_in(user)
    allow(SecureRandom).to receive(:hex).and_return('securerandomhex:thereisnospoon')
  end

  it 'commit/show.html' do
    params = {
      namespace_id: project.namespace,
      project_id: project,
      id: commit.id
    }

    get :show, params: params

    expect(response).to be_successful
  end
end
