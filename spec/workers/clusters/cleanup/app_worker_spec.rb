# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Cleanup::AppWorker do
  describe '#perform' do
    subject { worker_instance.perform(cluster.id) }

    let!(:worker_instance) { described_class.new }
    let!(:cluster) { create(:cluster, :project, :cleanup_uninstalling_applications, provider_type: :gcp) }
    let!(:logger) { worker_instance.send(:logger) }

    it_behaves_like 'cluster cleanup worker base specs'

    context 'when exceeded the execution limit' do
      subject { worker_instance.perform(cluster.id, worker_instance.send(:execution_limit)) }

      let(:worker_instance) { described_class.new }
      let(:logger) { worker_instance.send(:logger) }
      let!(:helm) { create(:clusters_applications_helm, :installed, cluster: cluster) }
      let!(:ingress) { create(:clusters_applications_ingress, :scheduled, cluster: cluster) }

      it 'logs the error' do
        expect(logger).to receive(:error)
        .with(
          hash_including(
            exception: 'ClusterCleanupMethods::ExceededExecutionLimitError',
            cluster_id: kind_of(Integer),
            class_name: described_class.name,
            applications: "helm:installed,ingress:scheduled",
            cleanup_status: cluster.cleanup_status_name,
            event: :failed_to_remove_cluster_and_resources,
            message: "exceeded execution limit of 10 tries"
          )
        )

        subject
      end
    end
  end
end
