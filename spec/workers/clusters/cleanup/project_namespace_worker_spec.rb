# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Cleanup::ProjectNamespaceWorker, feature_category: :deployment_management do
  describe '#perform' do
    context 'when cluster.cleanup_status is cleanup_removing_project_namespaces' do
      let!(:cluster) { create(:cluster, :with_environments, :cleanup_removing_project_namespaces) }
      let!(:worker_instance) { described_class.new }
      let!(:logger) { worker_instance.send(:logger) }

      it_behaves_like 'cluster cleanup worker base specs'

      it 'calls Clusters::Cleanup::ProjectNamespaceService' do
        expect_any_instance_of(Clusters::Cleanup::ProjectNamespaceService).to receive(:execute).once

        subject.perform(cluster.id)
      end

      context 'when exceeded the execution limit' do
        subject { worker_instance.perform(cluster.id, worker_instance.send(:execution_limit)) }

        it 'logs the error' do
          expect(logger).to receive(:error)
            .with(
              hash_including(
                exception: 'ClusterCleanupMethods::ExceededExecutionLimitError',
                cluster_id: kind_of(Integer),
                class_name: described_class.name,
                cleanup_status: cluster.cleanup_status_name,
                event: :failed_to_remove_cluster_and_resources,
                message: "exceeded execution limit of 10 tries"
              )
            )

          subject
        end
      end
    end

    context 'when cluster.cleanup_status is not cleanup_removing_project_namespaces' do
      let!(:cluster) { create(:cluster, :with_environments) }

      it 'does not call Clusters::Cleanup::ProjectNamespaceService' do
        expect(Clusters::Cleanup::ProjectNamespaceService).not_to receive(:new)

        subject.perform(cluster.id)
      end
    end
  end
end
