# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::DeactivateServiceWorker, '#perform' do
  context 'cluster exists' do
    describe 'prometheus service' do
      let(:service_name) { 'prometheus' }
      let!(:application) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }

      context 'prometheus service exists' do
        let!(:prometheus_service) { create(:prometheus_service, project: project, manual_configuration: false, active: true) }

        before do
          application.delete # prometheus service before save synchronises active stated with application existance.
        end

        context 'cluster type: group' do
          let(:group) { create(:group) }
          let(:project) { create(:project, group: group) }
          let(:cluster) { create(:cluster_for_group, :with_installed_helm, groups: [group]) }

          it 'ensures Prometheus service is deactivated' do
            expect { described_class.new.perform(cluster.id, service_name) }
              .to change { prometheus_service.reload.active }.from(true).to(false)
          end
        end

        context 'cluster type: project' do
          let(:project) { create(:project) }
          let(:cluster) { create(:cluster, :with_installed_helm, projects: [project]) }

          it 'ensures Prometheus service is deactivated' do
            expect { described_class.new.perform(cluster.id, service_name) }
              .to change { prometheus_service.reload.active }.from(true).to(false)
          end
        end

        context 'cluster type: instance' do
          let(:project) { create(:project) }
          let(:cluster) { create(:cluster, :with_installed_helm, :instance) }

          it 'ensures Prometheus service is deactivated' do
            expect { described_class.new.perform(cluster.id, service_name) }
              .to change { prometheus_service.reload.active }.from(true).to(false)
          end
        end
      end

      context 'prometheus service does not exist' do
        context 'cluster type: project' do
          let(:project) { create(:project) }
          let(:cluster) { create(:cluster, :with_installed_helm, projects: [project]) }

          it 'does not raise errors' do
            expect { described_class.new.perform(cluster.id, service_name) }.not_to raise_error
          end
        end
      end
    end
  end

  context 'cluster does not exist' do
    it 'raises Record Not Found error' do
      expect { described_class.new.perform(0, 'ignored in this context') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
