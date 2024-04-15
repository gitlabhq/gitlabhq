# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update Environment Canary Ingress', :clean_gitlab_redis_cache, feature_category: :deployment_management do
  include GraphqlHelpers
  include KubernetesHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:cluster) { create(:cluster, :project, projects: [project]) }
  let_it_be(:service) { create(:cluster_platform_kubernetes, :configured, cluster: cluster) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:deployment) { create(:deployment, :success, environment: environment, project: project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  let(:environment_id) { environment.to_global_id.to_s }
  let(:weight) { 25 }
  let(:actor) { developer }

  let(:mutation) do
    graphql_mutation(:environments_canary_ingress_update, id: environment_id, weight: weight)
  end

  before do
    stub_kubeclient_ingresses(environment.deployment_namespace, response: kube_ingresses_response(with_canary: true))
  end

  context 'when kubernetes accepted the patch request' do
    before do
      stub_kubeclient_ingresses(environment.deployment_namespace, method: :patch, resource_path: "/production-auto-deploy")
    end

    it 'updates successfully' do
      post_graphql_mutation(mutation, current_user: actor)

      expect(graphql_mutation_response(:environments_canary_ingress_update)['errors'])
        .to be_empty
    end
  end
end
