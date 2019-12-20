# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Cleanup::AppService do
  describe '#execute' do
    let!(:cluster) { create(:cluster, :project, :cleanup_uninstalling_applications, provider_type: :gcp) }
    let(:service) { described_class.new(cluster) }
    let(:logger) { service.send(:logger) }
    let(:log_meta) do
      {
        service: described_class.name,
        cluster_id: cluster.id,
        execution_count: 0
      }
    end

    subject { service.execute }

    shared_examples 'does not reschedule itself' do
      it 'does not reschedule itself' do
        expect(Clusters::Cleanup::AppWorker).not_to receive(:perform_in)
      end
    end

    context 'when cluster has no applications available or transitioning applications' do
      it_behaves_like 'does not reschedule itself'

      it 'transitions cluster to cleanup_removing_project_namespaces' do
        expect { subject }
          .to change { cluster.reload.cleanup_status_name }
          .from(:cleanup_uninstalling_applications)
          .to(:cleanup_removing_project_namespaces)
      end

      it 'schedules Clusters::Cleanup::ProjectNamespaceWorker' do
        expect(Clusters::Cleanup::ProjectNamespaceWorker).to receive(:perform_async).with(cluster.id)
        subject
      end

      it 'logs all events' do
        expect(logger).to receive(:info)
          .with(log_meta.merge(event: :schedule_remove_project_namespaces))

        subject
      end
    end

    context 'when cluster has uninstallable applications' do
      shared_examples 'reschedules itself' do
        it 'reschedules itself' do
          expect(Clusters::Cleanup::AppWorker)
            .to receive(:perform_in)
            .with(1.minute, cluster.id, 1)

          subject
        end
      end

      context 'has applications with dependencies' do
        let!(:helm) { create(:clusters_applications_helm, :installed, cluster: cluster) }
        let!(:ingress) { create(:clusters_applications_ingress, :installed, cluster: cluster) }
        let!(:cert_manager) { create(:clusters_applications_cert_manager, :installed, cluster: cluster) }
        let!(:jupyter) { create(:clusters_applications_jupyter, :installed, cluster: cluster) }

        it_behaves_like 'reschedules itself'

        it 'only uninstalls apps that are not dependencies for other installed apps' do
          expect(Clusters::Applications::UninstallWorker)
            .not_to receive(:perform_async).with(helm.name, helm.id)

          expect(Clusters::Applications::UninstallWorker)
            .not_to receive(:perform_async).with(ingress.name, ingress.id)

          expect(Clusters::Applications::UninstallWorker)
            .to receive(:perform_async).with(cert_manager.name, cert_manager.id)
            .and_call_original

          expect(Clusters::Applications::UninstallWorker)
            .to receive(:perform_async).with(jupyter.name, jupyter.id)
            .and_call_original

          subject
        end

        it 'logs application uninstalls and next execution' do
          expect(logger).to receive(:info)
            .with(log_meta.merge(event: :uninstalling_app, application: kind_of(String))).exactly(2).times
          expect(logger).to receive(:info)
            .with(log_meta.merge(event: :scheduling_execution, next_execution: 1))

          subject
        end

        context 'cluster is not cleanup_uninstalling_applications' do
          let!(:cluster) { create(:cluster, :project, provider_type: :gcp) }

          it_behaves_like 'does not reschedule itself'
        end
      end

      context 'when applications are still uninstalling/scheduled/depending on others' do
        let!(:helm) { create(:clusters_applications_helm, :installed, cluster: cluster) }
        let!(:ingress) { create(:clusters_applications_ingress, :scheduled, cluster: cluster) }
        let!(:runner) { create(:clusters_applications_runner, :uninstalling, cluster: cluster) }

        it_behaves_like 'reschedules itself'

        it 'does not call the uninstallation service' do
          expect(Clusters::Applications::UninstallWorker).not_to receive(:new)

          subject
        end
      end
    end
  end
end
