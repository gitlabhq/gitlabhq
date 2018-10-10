# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Gcp::ServicesAccountService, '#execute' do
  include GoogleApi::CloudPlatformHelpers
  include KubernetesHelpers

  let(:api_url) { 'https://111.111.111.111' }
  let(:cluster) { create(:cluster, :project, :providing_by_gcp, platform_kubernetes: create(:cluster_platform_kubernetes)) }
  let(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, cluster_project: cluster.cluster_projects.first) }
  let(:namespace) { kubernetes_namespace.namespace }

  let(:kubeclient) do
    Gitlab::Kubernetes::KubeClient.new(
      api_url,
      ['api', 'apis/rbac.authorization.k8s.io'],
      auth_options: { username: 'sample-username', password: 'sample-password' }
    )
  end

  subject { described_class.new(kubeclient, cluster).execute }

  shared_context 'shared kubernetes requests' do
    before do
      stub_kubeclient_discover(api_url)
      stub_kubeclient_get_namespace(api_url)
      stub_kubeclient_create_service_account(api_url)
      stub_kubeclient_create_secret(api_url)

      stub_kubeclient_get_namespace(api_url, namespace: namespace)
      stub_kubeclient_create_service_account(api_url, namespace: namespace)
      stub_kubeclient_create_secret(api_url, namespace: namespace)
    end
  end

  shared_examples 'creates default and namespaced services accounts' do
    it 'creates default service account' do
      subject

      expect(WebMock).to have_requested(:post, api_url + "/api/v1/namespaces/default/serviceaccounts").with(
        body: hash_including(
          kind: 'ServiceAccount',
          metadata: { name: 'gitlab', namespace: 'default' }
        )
      )
    end

    it 'creates a namespaced service account' do
      subject

      expect(WebMock).to have_requested(:post, api_url + "/api/v1/namespaces/#{namespace}/serviceaccounts").with(
        body: hash_including(
          kind: 'ServiceAccount',
          metadata: { name: "#{namespace}-service-account", namespace: namespace }
        )
      )
    end

    it 'creates a default token' do
      subject

      expect(WebMock).to have_requested(:post, api_url + "/api/v1/namespaces/default/secrets").with(
        body: hash_including(
          kind: 'Secret',
          metadata: {
            name: 'gitlab-token',
            namespace: 'default',
            annotations: {
              'kubernetes.io/service-account.name': 'gitlab'
            }
          }
        )
      )
    end

    it 'creates a restricted token' do
      subject

      expect(WebMock).to have_requested(:post, api_url + "/api/v1/namespaces/#{namespace}/secrets").with(
        body: hash_including(
          kind: 'Secret',
          metadata: {
            name: "#{namespace}-token",
            namespace: namespace,
            annotations: {
              'kubernetes.io/service-account.name': "#{namespace}-service-account"
            }
          }
        )
      )
    end
  end

  context 'With an ABAC cluster' do
    include_context 'shared kubernetes requests'

    it_behaves_like 'creates default and namespaced services accounts'
  end

  context 'With an RBAC cluster' do
    include_context 'shared kubernetes requests'

    before do
      cluster.platform_kubernetes.rbac!

      stub_kubeclient_create_cluster_role_binding(api_url)
      stub_kubeclient_create_role_binding(api_url, namespace: namespace)
    end

    it_behaves_like 'creates default and namespaced services accounts'

    it 'creates a cluster role binding with cluster-admin access' do
      subject

      expect(WebMock).to have_requested(:post, api_url + "/apis/rbac.authorization.k8s.io/v1/clusterrolebindings").with(
        body: hash_including(
          kind: 'ClusterRoleBinding',
          metadata: { name: 'gitlab-admin' },
          roleRef: {
            apiGroup: 'rbac.authorization.k8s.io',
            kind: 'ClusterRole',
            name: 'cluster-admin'
          },
          subjects: [
            {
              kind: 'ServiceAccount',
              name: 'gitlab',
              namespace: 'default'
            }
          ]
        )
      )
    end

    it 'creates a namespaced role binding with edit access' do
      subject

      expect(WebMock).to have_requested(:post, api_url + "/apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/rolebindings").with(
        body: hash_including(
          kind: 'RoleBinding',
          metadata: { name: "gitlab-#{namespace}", namespace: "#{namespace}" },
          roleRef: {
            apiGroup: 'rbac.authorization.k8s.io',
            kind: 'Role',
            name: 'edit'
          },
          subjects: [
            {
              kind: 'ServiceAccount',
              name: "#{namespace}-service-account",
              namespace: "#{namespace}"
            }
          ]
        )
      )
    end
  end
end
