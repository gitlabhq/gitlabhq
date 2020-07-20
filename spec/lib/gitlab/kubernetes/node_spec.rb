# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::Node do
  include KubernetesHelpers

  describe '#all' do
    let(:cluster) { create(:cluster, :provided_by_user, :group) }
    let(:expected_nodes) { [] }

    before do
      stub_kubeclient_nodes_and_nodes_metrics(cluster.platform.api_url)
    end

    subject { described_class.new(cluster).all }

    context 'when connection to the cluster is successful' do
      let(:expected_nodes) { [kube_node.merge(kube_node_metrics)] }

      it { is_expected.to eq(expected_nodes) }
    end

    context 'when cluster cannot be reached' do
      before do
        allow(cluster.kubeclient.core_client).to receive(:discover)
          .and_raise(SocketError)
      end

      it { is_expected.to eq(expected_nodes) }
    end

    context 'when cluster cannot be authenticated to' do
      before do
        allow(cluster.kubeclient.core_client).to receive(:discover)
          .and_raise(OpenSSL::X509::CertificateError.new('Certificate error'))
      end

      it { is_expected.to eq(expected_nodes) }
    end

    context 'when Kubeclient::HttpError is raised' do
      before do
        allow(cluster.kubeclient.core_client).to receive(:discover)
          .and_raise(Kubeclient::HttpError.new(403, 'Forbidden', nil))
      end

      it { is_expected.to eq(expected_nodes) }
    end

    context 'when an uncategorised error is raised' do
      before do
        allow(cluster.kubeclient.core_client).to receive(:discover)
          .and_raise(StandardError)
      end

      it { is_expected.to eq(expected_nodes) }

      it 'notifies Sentry' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(StandardError), hash_including(cluster_id: cluster.id))
          .once

        subject
      end
    end
  end
end
