# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Gcp::Kubernetes::CreateServiceAccountService do
  include KubernetesHelpers

  let(:service) { described_class.new(kubeclient, rbac: rbac) }

  describe '#execute' do
    let(:rbac) { false }
    let(:api_url) { 'http://111.111.111.111' }
    let(:username) { 'admin' }
    let(:password) { 'xxx' }

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
        stub_kubeclient_create_service_account(api_url)
        stub_kubeclient_create_secret(api_url)
      end

      shared_examples 'creates service account and token' do
        it 'creates a kubernetes service account' do
          subject

          expect(WebMock).to have_requested(:post, api_url + '/api/v1/namespaces/default/serviceaccounts').with(
            body: hash_including(
              kind: 'ServiceAccount',
              metadata: { name: 'gitlab', namespace: 'default' }
            )
          )
        end

        it 'creates a kubernetes secret of type ServiceAccountToken' do
          subject

          expect(WebMock).to have_requested(:post, api_url + '/api/v1/namespaces/default/secrets').with(
            body: hash_including(
              kind: 'Secret',
              metadata: {
                name: 'gitlab-token',
                namespace: 'default',
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
          stub_kubeclient_create_cluster_role_binding(api_url)
        end

        it_behaves_like 'creates service account and token'

        it 'creates a kubernetes cluster role binding' do
          subject

          expect(WebMock).to have_requested(:post, api_url + '/apis/rbac.authorization.k8s.io/v1/clusterrolebindings').with(
            body: hash_including(
              kind: 'ClusterRoleBinding',
              metadata: { name: 'gitlab-admin' },
              roleRef: {
                apiGroup: 'rbac.authorization.k8s.io',
                kind: 'ClusterRole',
                name: 'cluster-admin'
              },
              subjects: [{ kind: 'ServiceAccount', namespace: 'default', name: 'gitlab' }]
            )
          )
        end
      end
    end
  end
end
