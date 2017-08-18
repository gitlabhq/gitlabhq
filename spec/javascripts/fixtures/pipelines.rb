require 'spec_helper'

describe Projects::PipelinesController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'pipelines-project') }
  let(:commit) { create(:commit, project: project) }
  let(:commit_without_author) { RepoHelpers.another_sample_commit }
  let!(:user) { create(:user, email: commit.author_email) }
  let!(:pipeline) { create(:ci_pipeline, project: project, sha: commit.id, user: user) }
  let!(:pipeline_without_author) { create(:ci_pipeline, project: project, sha: commit_without_author.id) }
  let!(:pipeline_without_commit) { create(:ci_pipeline, project: project, sha: '0000') }

  render_views

  before(:all) do
    clean_frontend_fixtures('pipelines/')
  end

  before do
    sign_in(admin)
  end

  it 'pipelines/pipelines.json' do |example|
    get :index,
      namespace_id: namespace,
      project_id: project,
      format: :json

    expect(response).to be_success
    store_frontend_fixture(response, example.description)
  end
end
