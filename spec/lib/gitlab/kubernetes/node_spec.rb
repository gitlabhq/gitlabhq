# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::Node do
  include KubernetesHelpers

  describe '#all' do
    let(:cluster) { create(:cluster, :provided_by_user, :group) }
    let(:expected_nodes) { nil }
    let(:nodes) { [kube_node.merge(kube_node_metrics)] }

    subject { described_class.new(cluster).all }

    before do
      stub_kubeclient_nodes_and_nodes_metrics(cluster.platform.api_url)
    end

    context 'when connection to the cluster is successful' do
      let(:expected_nodes) { { nodes: nodes } }

      it { is_expected.to eq(expected_nodes) }
    end

    context 'when there is a connection error' do
      using RSpec::Parameterized::TableSyntax

      where(:error, :error_status) do
        SocketError                             | :kubernetes_connection_error
        OpenSSL::X509::CertificateError         | :kubernetes_authentication_error
        StandardError                           | :unknown_error
        Kubeclient::HttpError.new(408, "", nil) | :kubeclient_http_error
      end

      context 'when there is an error while querying nodes' do
        with_them do
          before do
            allow(cluster.kubeclient).to receive(:get_nodes).and_raise(error)
          end

          it { is_expected.to eq({ node_connection_error: error_status }) }
        end
      end

      context 'when there is an error while querying metrics' do
        with_them do
          before do
            allow(cluster.kubeclient).to receive(:get_nodes).and_return({ response: nodes })
            allow(cluster.kubeclient).to receive(:metrics_client).and_raise(error)
          end

          it { is_expected.to eq({ nodes: nodes, metrics_connection_error: error_status }) }
        end
      end
    end

    context 'when an uncategorised error is raised' do
      before do
        allow(cluster.kubeclient.core_client).to receive(:discover)
          .and_raise(StandardError)
      end

      it { is_expected.to eq({ node_connection_error: :unknown_error }) }

      it 'notifies Sentry' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(StandardError), hash_including(cluster_id: cluster.id))
          .once

        subject
      end
    end
  end
end
