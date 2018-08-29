# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Gcp::Kubernetes::CreateServiceAccountService do
  include KubernetesHelpers

  let(:service) { described_class.new(api_url, ca_pem, username, password) }

  describe '#execute' do
    subject { service.execute }

    let(:api_url) { 'http://111.111.111.111' }
    let(:ca_pem) { '' }
    let(:username) { 'admin' }
    let(:password) { 'xxx' }

    context 'when params are correct' do
      before do
        stub_kubeclient_discover(api_url)
        stub_kubeclient_create_service_account(api_url)
        stub_kubeclient_create_cluster_role_binding(api_url)
      end

      it 'creates a kubernetes service account' do
        subject

        expect(WebMock).to have_requested(:post, api_url + '/api/v1/namespaces/default/serviceaccounts').with(
          body: hash_including(
            metadata: { name: 'gitlab', namespace: 'default' }
          )
        )
      end

      it 'creates a kubernetes cluster role binding' do
        subject

        expect(WebMock).to have_requested(:post, api_url + '/apis/rbac.authorization.k8s.io/v1/clusterrolebindings').with(
          body: hash_including(
            metadata: { name: 'gitlab-admin' },
            roleRef: { apiGroup: 'rbac.authorization.k8s.io', kind: 'ClusterRole', name: 'cluster-admin' },
            subjects: [{ kind: 'ServiceAccount', namespace: 'default', name: 'gitlab' }]
          )
        )
      end
    end

    context 'when api_url is nil' do
      let(:api_url) { nil }

      it { expect { subject }.to raise_error("Incomplete settings") }
    end

    context 'when username is nil' do
      let(:username) { nil }

      it { expect { subject }.to raise_error("Incomplete settings") }
    end

    context 'when password is nil' do
      let(:password) { nil }

      it { expect { subject }.to raise_error("Incomplete settings") }
    end
  end
end
