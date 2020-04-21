# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::Helm::BaseCommand do
  let(:application) { create(:clusters_applications_helm) }
  let(:rbac) { false }

  let(:test_class) do
    Class.new do
      include Gitlab::Kubernetes::Helm::BaseCommand

      def initialize(rbac)
        @rbac = rbac
      end

      def name
        "test-class-name"
      end

      def rbac?
        @rbac
      end

      def files
        {
          some: 'value'
        }
      end
    end
  end

  let(:base_command) do
    test_class.new(rbac)
  end

  subject { base_command }

  it_behaves_like 'helm commands' do
    let(:commands) { '' }
  end

  describe '#pod_resource' do
    subject { base_command.pod_resource }

    it 'returns a kubeclient resoure with pod content for application' do
      is_expected.to be_an_instance_of ::Kubeclient::Resource
    end

    context 'when rbac is true' do
      let(:rbac) { true }

      it 'also returns a kubeclient resource' do
        is_expected.to be_an_instance_of ::Kubeclient::Resource
      end
    end
  end

  describe '#pod_name' do
    subject { base_command.pod_name }

    it { is_expected.to eq('install-test-class-name') }
  end

  describe '#service_account_resource' do
    let(:resource) do
      Kubeclient::Resource.new(metadata: { name: 'tiller', namespace: 'gitlab-managed-apps' })
    end

    subject { base_command.service_account_resource }

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

    subject { base_command.cluster_role_binding_resource }

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
