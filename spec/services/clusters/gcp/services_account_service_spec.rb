# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Gcp::ServicesAccountService, '#execute' do
  include GoogleApi::CloudPlatformHelpers
  include KubernetesHelpers

  let(:endpoint) { '111.111.111.111' }
  let(:api_url) { 'https://' + endpoint }
  let(:cluster) { create(:cluster, :project, :providing_by_gcp, platform_kubernetes: create(:cluster_platform_kubernetes)) }
  let(:username) { 'sample-username' }
  let(:password) { 'sample-password' }

  let(:kubeclient) do
    Gitlab::Kubernetes::KubeClient.new(
      api_url,
      ['api', 'apis/rbac.authorization.k8s.io'],
      auth_options: { username: username, password: password }
    )
  end

  subject { described_class.new(kubeclient, cluster).execute }

  context 'With an ABAC cluster' do
    before do
      stub_kubeclient_discover(api_url)
      stub_kubeclient_create_service_account(api_url)
      stub_kubeclient_create_secret(api_url)
    end

    it 'creates default service account' do
      subject

      expect(WebMock).to have_requested(:post, api_url + "/api/v1/namespaces/default/serviceaccounts").with(
        body: hash_including(
          kind: 'ServiceAccount',
          metadata: { name: 'gitlab', namespace: 'default' }
        )
      )
    end
  end

  context 'With an RBAC cluster' do
    let(:namespace) { "#{cluster.project.path}-#{cluster.project.id}" }

    before do
      cluster.platform_kubernetes.rbac!

      stub_kubeclient_discover(api_url)
      stub_kubeclient_create_service_account(api_url)
      stub_kubeclient_create_secret(api_url)

      stub_kubeclient_create_namespace(api_url)
      stub_kubeclient_get_namespace(api_url, namespace: namespace)

      stub_kubeclient_create_service_account(api_url, namespace: namespace)
      stub_kubeclient_create_secret(api_url, namespace: namespace)
      stub_kubeclient_create_role_binding(api_url, namespace: namespace)
    end

    it 'creates namespaced service account' do
      subject

      expect(WebMock).to have_requested(:post, api_url + "/api/v1/namespaces/#{namespace}/serviceaccounts").with(
        body: hash_including(
          kind: 'ServiceAccount',
          metadata: { name: "gitlab-#{namespace}", namespace: namespace }
        )
      )
    end
  end
end
