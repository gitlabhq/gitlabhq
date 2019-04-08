# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::RoleBinding, '#generate' do
  let(:role_name) { 'edit' }
  let(:namespace) { 'my-namespace' }
  let(:service_account_name) { 'my-service-account' }

  let(:subjects) do
    [
      {
        kind: 'ServiceAccount',
        name: service_account_name,
        namespace: namespace
      }
    ]
  end

  let(:role_ref) do
    {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: role_name
    }
  end

  let(:resource) do
    ::Kubeclient::Resource.new(
      metadata: { name: "gitlab-#{namespace}", namespace: namespace },
      roleRef: role_ref,
      subjects: subjects
    )
  end

  subject do
    described_class.new(
      name: "gitlab-#{namespace}",
      role_name: role_name,
      namespace: namespace,
      service_account_name: service_account_name
    ).generate
  end

  it 'builds a Kubeclient Resource' do
    is_expected.to eq(resource)
  end
end
