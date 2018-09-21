# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Gcp::Kubernetes::CreateServiceAccountService do
  include KubernetesHelpers

  let(:service) { described_class.new(kubeclient, name: name, namespace: namespace, rbac: rbac) }

  describe '#execute' do
    let(:rbac) { false }
    let(:api_url) { 'http://111.111.111.111' }
    let(:username) { 'admin' }
    let(:password) { 'xxx' }

    let(:cluster) do
      create(:cluster,
             :project, :provided_by_gcp,
             platform_kubernetes: create(:cluster_platform_kubernetes, :configured)
            )
    end

    let(:platform_kubernetes) { cluster.platform_kubernetes }
    let(:namespace) { platform_kubernetes.actual_namespace }
    let(:name) { platform_kubernetes.service_account_name }

    let(:kubeclient) do
      Gitlab::Kubernetes::KubeClient.new(
        api_url,
        ['api', 'apis/rbac.authorization.k8s.io'],
        auth_options: { username: username, password: password }
      )
    end

    subject { service.execute }

    context 'when params are correct' do
      before do
        stub_kubeclient_discover(api_url)
        stub_kubeclient_create_service_account(api_url, namespace: namespace)
        stub_kubeclient_create_secret(api_url, namespace: namespace)
      end

      shared_examples 'creates service account and token' do
        it 'creates a kubernetes service account' do
          subject

          expect(WebMock).to have_requested(:post, api_url + "/api/v1/namespaces/#{namespace}/serviceaccounts").with(
            body: hash_including(
              kind: 'ServiceAccount',
              metadata: { name: name, namespace: namespace }
            )
          )
        end

        it 'creates a kubernetes secret of type ServiceAccountToken' do
          subject

          expect(WebMock).to have_requested(:post, api_url + "/api/v1/namespaces/#{namespace}/secrets").with(
            body: hash_including(
              kind: 'Secret',
              metadata: {
                name: 'gitlab-token',
                namespace: namespace,
                annotations: {
                  'kubernetes.io/service-account.name': 'gitlab'
                }
              },
              type: 'kubernetes.io/service-account-token'
            )
          )
        end
      end

      context 'abac enabled cluster' do
        it_behaves_like 'creates service account and token'
      end

      context 'rbac enabled cluster' do
        let(:rbac) { true }

        before do
          stub_kubeclient_create_role_binding(api_url, namespace: namespace)
        end

        it_behaves_like 'creates service account and token'

        it 'creates a kubernetes role binding with edit access' do
          subject

          expect(WebMock).to have_requested(:post, api_url + "/apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/rolebindings").with(
            body: hash_including(
              kind: 'RoleBinding',
              metadata: { name: 'gitlab-edit', namespace: namespace },
              roleRef: {
                apiGroup: 'rbac.authorization.k8s.io',
                kind: 'Role',
                name: 'edit'
              },
              subjects: [{ kind: 'ServiceAccount', name: 'gitlab', namespace: namespace }]
            )
          )
        end
      end
    end
  end
end
