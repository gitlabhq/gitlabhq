# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::ActivateServiceWorker, '#perform' do
  context 'cluster exists' do
    describe 'prometheus service' do
      let(:service_name) { 'prometheus' }

      before do
        create(:clusters_applications_prometheus, :installed, cluster: cluster)
      end

      context 'cluster type: group' do
        let(:group) { create(:group) }
        let(:project) { create(:project, group: group) }
        let(:cluster) { create(:cluster_for_group, :with_installed_helm, groups: [group]) }

        it 'ensures Prometheus service is activated' do
          expect { described_class.new.perform(cluster.id, service_name) }
            .to change { project.reload.prometheus_service&.active }.from(nil).to(true)
        end
      end

      context 'cluster type: project' do
        let(:project) { create(:project) }
        let(:cluster) { create(:cluster, :with_installed_helm, projects: [project]) }

        it 'ensures Prometheus service is activated' do
          expect { described_class.new.perform(cluster.id, service_name) }
            .to change { project.reload.prometheus_service&.active }.from(nil).to(true)
        end
      end

      context 'cluster type: instance' do
        let(:project) { create(:project) }
        let(:cluster) { create(:cluster, :instance) }

        it 'ensures Prometheus service is activated' do
          expect { described_class.new.perform(cluster.id, service_name) }
            .to change { project.reload.prometheus_service&.active }.from(nil).to(true)
        end
      end
    end
  end

  context 'cluster does not exist' do
    it 'does not raise Record Not Found error' do
      expect { described_class.new.perform(0, 'ignored in this context') }.not_to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
