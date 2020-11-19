# frozen_string_literal: true

RSpec.shared_examples 'helm command generator' do
  describe '#generate_script' do
    let(:helm_setup) do
      <<~EOS
         set -xeo pipefail
      EOS
    end

    it 'returns appropriate command' do
      expect(subject.generate_script.strip).to eq((helm_setup + commands).strip)
    end
  end
end

RSpec.shared_examples 'helm command' do
  describe 'HELM_VERSION' do
    subject { command.class::HELM_VERSION }

    it { is_expected.to match(/\d+\.\d+\.\d+/) }
  end

  describe '#env' do
    subject { command.env }

    it { is_expected.to be_a Hash }
  end

  describe '#rbac?' do
    subject { command.rbac? }

    context 'rbac is enabled' do
      let(:rbac) { true }

      it { is_expected.to be_truthy }
    end

    context 'rbac is not enabled' do
      let(:rbac) { false }

      it { is_expected.to be_falsey }
    end
  end

  describe '#pod_resource' do
    subject { command.pod_resource }

    context 'rbac is enabled' do
      let(:rbac) { true }

      it { is_expected.to be_an_instance_of ::Kubeclient::Resource }

      it 'generates a pod that uses the tiller serviceAccountName' do
        expect(subject.spec.serviceAccountName).to eq('tiller')
      end
    end

    context 'rbac is not enabled' do
      let(:rbac) { false }

      it { is_expected.to be_an_instance_of ::Kubeclient::Resource }

      it 'generates a pod that uses the default serviceAccountName' do
        expect(subject.spec.serviceAcccountName).to be_nil
      end
    end
  end

  describe '#config_map_resource' do
    subject { command.config_map_resource }

    let(:metadata) do
      {
        name: "values-content-configuration-#{command.name}",
        namespace: 'gitlab-managed-apps',
        labels: { name: "values-content-configuration-#{command.name}" }
      }
    end

    let(:resource) { ::Kubeclient::Resource.new(metadata: metadata, data: command.files) }

    it 'returns a KubeClient resource with config map content for the application' do
      is_expected.to eq(resource)
    end
  end

  describe '#service_account_resource' do
    let(:resource) do
      Kubeclient::Resource.new(metadata: { name: 'tiller', namespace: 'gitlab-managed-apps' })
    end

    subject { command.service_account_resource }

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

    subject(:cluster_role_binding_resource) { command.cluster_role_binding_resource }

    context 'rbac is enabled' do
      let(:rbac) { true }

      it 'generates a Kubeclient resource for the ClusterRoleBinding for tiller' do
        is_expected.to eq(resource)
      end

      it 'binds the account in #service_account_resource' do
        expect(cluster_role_binding_resource.subjects.first.name).to eq(command.service_account_resource.metadata.name)
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
