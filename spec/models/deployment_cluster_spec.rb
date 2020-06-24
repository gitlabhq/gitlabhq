# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeploymentCluster do
  let(:cluster) { create(:cluster) }
  let(:deployment) { create(:deployment) }
  let(:kubernetes_namespace) { 'an-example-namespace' }

  subject { described_class.new(deployment: deployment, cluster: cluster, kubernetes_namespace: kubernetes_namespace) }

  it { is_expected.to belong_to(:deployment).required }
  it { is_expected.to belong_to(:cluster).required }

  it do
    is_expected.to have_attributes(
      cluster_id: cluster.id,
      deployment_id: deployment.id,
      kubernetes_namespace: kubernetes_namespace
    )
  end
end
