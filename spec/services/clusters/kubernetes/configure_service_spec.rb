# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Kubernetes::ConfigureService, '#execute' do
  include KubernetesHelpers

  let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
  let(:platform) { cluster.platform }
  let(:api_url) { 'https://kubernetes.example.com' }
  let(:namespace) { "#{cluster.project.path}-#{cluster.project.id}" }

  subject { described_class.new(cluster).execute }

  before do
    stub_kubeclient_discover(api_url)
    stub_kubeclient_get_namespace(api_url)
    stub_kubeclient_create_service_account(api_url)
    stub_kubeclient_create_secret(api_url)

    stub_kubeclient_get_namespace(api_url, namespace: namespace)
    stub_kubeclient_create_service_account(api_url, namespace: namespace)
    stub_kubeclient_create_secret(api_url, namespace: namespace)

    stub_kubeclient_get_secret(
      api_url,
      {
        metadata_name: "#{namespace}-token",
        token: Base64.encode64('sample-token'),
        namespace: namespace
      }
    )
  end

  it 'creates a kubernetes namespace' do
    expect do
      subject
    end.to change(Clusters::KubernetesNamespace, :count).by(1)
  end

  it 'calls ServicesAccountService' do
    expect_any_instance_of(Clusters::Gcp::ServicesAccountService).to receive(:execute).once

    subject
  end

  it 'configures kubernetes token' do
    subject

    kubernetes_namespace = cluster.cluster_projects.first.kubernetes_namespace
    expect(kubernetes_namespace.encrypted_service_account_token).to be_present
  end
end
