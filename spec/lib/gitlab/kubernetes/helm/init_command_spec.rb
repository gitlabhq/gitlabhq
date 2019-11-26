# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::Helm::InitCommand do
  let(:application) { create(:clusters_applications_helm) }
  let(:rbac) { false }
  let(:files) { {} }
  let(:init_command) { described_class.new(name: application.name, files: files, rbac: rbac) }

  let(:commands) do
    <<~EOS
    helm init --tiller-tls --tiller-tls-verify --tls-ca-cert /data/helm/helm/config/ca.pem --tiller-tls-cert /data/helm/helm/config/cert.pem --tiller-tls-key /data/helm/helm/config/key.pem
    EOS
  end

  subject { init_command }

  it_behaves_like 'helm commands'

  context 'on a rbac-enabled cluster' do
    let(:rbac) { true }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
        helm init --tiller-tls --tiller-tls-verify --tls-ca-cert /data/helm/helm/config/ca.pem --tiller-tls-cert /data/helm/helm/config/cert.pem --tiller-tls-key /data/helm/helm/config/key.pem --service-account tiller
        EOS
      end
    end
  end

  describe '#rbac?' do
    subject { init_command.rbac? }

    context 'rbac is enabled' do
      let(:rbac) { true }

      it { is_expected.to be_truthy }
    end

    context 'rbac is not enabled' do
      let(:rbac) { false }

      it { is_expected.to be_falsey }
    end
  end

  describe '#config_map_resource' do
    let(:metadata) do
      {
        name: 'values-content-configuration-helm',
        namespace: 'gitlab-managed-apps',
        labels: { name: 'values-content-configuration-helm' }
      }
    end

    let(:resource) { ::Kubeclient::Resource.new(metadata: metadata, data: files) }

    subject { init_command.config_map_resource }

    it 'returns a KubeClient resource with config map content for the application' do
      is_expected.to eq(resource)
    end
  end

  describe '#pod_resource' do
    subject { init_command.pod_resource }

    context 'rbac is enabled' do
      let(:rbac) { true }

      it 'generates a pod that uses the tiller serviceAccountName' do
        expect(subject.spec.serviceAccountName).to eq('tiller')
      end
    end

    context 'rbac is not enabled' do
      let(:rbac) { false }

      it 'generates a pod that uses the default serviceAccountName' do
        expect(subject.spec.serviceAcccountName).to be_nil
      end
    end
  end

  describe '#service_account_resource' do
    let(:resource) do
      Kubeclient::Resource.new(metadata: { name: 'tiller', namespace: 'gitlab-managed-apps' })
    end

    subject { init_command.service_account_resource }

    context 'rbac is enabled' do
      let(:rbac) { true }

      it 'generates a Kubeclient resource for the tiller ServiceAccount' do
        is_expected.to eq(resource)
      end
    end

    context 'rbac is not enabled' do
      let(:rbac) { false }

      it 'generates nothing' do
        is_expected.to be_nil
      end
    end
  end

  describe '#cluster_role_binding_resource' do
    let(:resource) do
      Kubeclient::Resource.new(
        metadata: { name: 'tiller-admin' },
        roleRef: { apiGroup: 'rbac.authorization.k8s.io', kind: 'ClusterRole', name: 'cluster-admin' },
        subjects: [{ kind: 'ServiceAccount', name: 'tiller', namespace: 'gitlab-managed-apps' }]
      )
    end

    subject { init_command.cluster_role_binding_resource }

    context 'rbac is enabled' do
      let(:rbac) { true }

      it 'generates a Kubeclient resource for the ClusterRoleBinding for tiller' do
        is_expected.to eq(resource)
      end
    end

    context 'rbac is not enabled' do
      let(:rbac) { false }

      it 'generates nothing' do
        is_expected.to be_nil
      end
    end
  end
end
