# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Kubernetes::ConfigureService, '#execute' do
  include KubernetesHelpers

  let(:cluster) { create(:cluster, :provided_by_gcp) }
  let(:cluster_project) { create(:cluster_project, cluster: cluster) }
  let(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, cluster_project: cluster_project) }
  let(:kubeclient) { platform.kubeclient }
  let(:platform) { kubernetes_namespace.cluster.platform_kubernetes }
  let(:namespace) { "#{cluster_project.project.path}-#{cluster_project.project_id}" }

  let(:service) do
    described_class.new(platform)
  end

  subject { service.execute }

  before do
    api_url = 'https://kubernetes.example.com'

    stub_kubeclient_discover(api_url)
    stub_kubeclient_get_namespace(api_url, namespace: namespace)
    stub_kubeclient_create_namespace(api_url)
  end

  it 'creates a kubernetes namespace' do
    expect(kubeclient).to receive(:get_namespace).once.ordered
    expect(kubeclient).to receive(:create_namespace).once.ordered

    subject
  end
end
