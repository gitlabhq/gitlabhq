# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::ClusterRoleBinding do
  let(:cluster_role_binding) { described_class.new(name, cluster_role_name, subjects) }
  let(:name) { 'cluster-role-binding-name' }
  let(:cluster_role_name) { 'cluster-admin' }

  let(:subjects) { [{ kind: 'ServiceAccount', name: 'sa', namespace: 'ns' }] }

  describe '#generate' do
    let(:role_ref) do
      {
        apiGroup: 'rbac.authorization.k8s.io',
        kind: 'ClusterRole',
        name: cluster_role_name
      }
    end

    let(:resource) do
      ::Kubeclient::Resource.new(
        metadata: { name: name },
        roleRef: role_ref,
        subjects: subjects
      )
    end

    subject { cluster_role_binding.generate }

    it 'builds a Kubeclient Resource' do
      is_expected.to eq(resource)
    end
  end
end
