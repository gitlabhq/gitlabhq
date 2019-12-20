# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Cleanup::ProjectNamespaceService do
  describe '#execute' do
    subject { service.execute }

    let!(:service) { described_class.new(cluster) }
    let!(:cluster) { create(:cluster, :with_environments, :cleanup_removing_project_namespaces) }
    let!(:logger) { service.send(:logger) }
    let(:log_meta) do
      {
        service: described_class.name,
        cluster_id: cluster.id,
        execution_count: 0
      }
    end
    let(:kubeclient_instance_double) do
      instance_double(Gitlab::Kubernetes::KubeClient, delete_namespace: nil, delete_service_account: nil)
    end

    before do
      allow_any_instance_of(Clusters::Cluster).to receive(:kubeclient).and_return(kubeclient_instance_double)
    end

    context 'when cluster has namespaces to be deleted' do
      it 'deletes namespaces from cluster' do
        expect(kubeclient_instance_double).to receive(:delete_namespace)
          .with cluster.kubernetes_namespaces[0].namespace
        expect(kubeclient_instance_double).to receive(:delete_namespace)
          .with(cluster.kubernetes_namespaces[1].namespace)

        subject
      end

      it 'deletes namespaces from database' do
        expect { subject }.to change { cluster.kubernetes_namespaces.exists? }.from(true).to(false)
      end

      it 'schedules ::ServiceAccountWorker' do
        expect(Clusters::Cleanup::ServiceAccountWorker).to receive(:perform_async).with(cluster.id)
        subject
      end

      it 'logs all events' do
        expect(logger).to receive(:info)
          .with(
            log_meta.merge(
              event: :deleting_project_namespace,
              namespace: cluster.kubernetes_namespaces[0].namespace))
        expect(logger).to receive(:info)
          .with(
            log_meta.merge(
              event: :deleting_project_namespace,
              namespace: cluster.kubernetes_namespaces[1].namespace))

        subject
      end
    end

    context 'when cluster has no namespaces' do
      let!(:cluster) { create(:cluster, :cleanup_removing_project_namespaces) }

      it 'schedules Clusters::Cleanup::ServiceAccountWorker' do
        expect(Clusters::Cleanup::ServiceAccountWorker).to receive(:perform_async).with(cluster.id)

        subject
      end

      it 'transitions to cleanup_removing_service_account' do
        expect { subject }
          .to change { cluster.reload.cleanup_status_name }
          .from(:cleanup_removing_project_namespaces)
          .to(:cleanup_removing_service_account)
      end

      it 'does not try to delete namespaces' do
        expect(kubeclient_instance_double).not_to receive(:delete_namespace)

        subject
      end
    end
  end
end
