require 'spec_helper'

describe Projects::ClustersController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace) }
  let(:cluster) { project.create_cluster!(gcp_cluster_name: "gke-test-creation-1", gcp_project_id: 'gitlab-internal-153318', gcp_cluster_zone: 'us-central1-a', gcp_cluster_size: '1', project_namespace: 'aaa', gcp_machine_type: 'n1-standard-1')}

  render_views

  before(:all) do
    clean_frontend_fixtures('clusters/')
  end

  before do
    sign_in(admin)
  end

  after do
    remove_repository(project)
  end

  it 'clusters/show_cluster.html.raw' do |example|
    get :show,
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: cluster

    expect(response).to be_success
    store_frontend_fixture(response, example.description)
  end
end
