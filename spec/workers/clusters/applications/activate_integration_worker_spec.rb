# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Applications::ActivateIntegrationWorker, '#perform', feature_category: :deployment_management do
  context 'when cluster exists' do
    describe 'prometheus integration' do
      let(:integration_name) { 'prometheus' }

      before do
        create(:clusters_integrations_prometheus, cluster: cluster)
      end

      context 'with cluster type: group' do
        let(:group) { create(:group) }
        let(:project) { create(:project, group: group) }
        let(:cluster) { create(:cluster_for_group, groups: [group]) }

        it 'ensures Prometheus integration is activated' do
          expect { described_class.new.perform(cluster.id, integration_name) }
            .to change { project.reload.prometheus_integration&.active }.from(nil).to(true)
        end
      end

      context 'with cluster type: project' do
        let(:project) { create(:project) }
        let(:cluster) { create(:cluster, projects: [project]) }

        it 'ensures Prometheus integration is activated' do
          expect { described_class.new.perform(cluster.id, integration_name) }
            .to change { project.reload.prometheus_integration&.active }.from(nil).to(true)
        end
      end

      context 'with cluster type: instance' do
        let(:project) { create(:project) }
        let(:cluster) { create(:cluster, :instance) }

        it 'ensures Prometheus integration is activated' do
          expect { described_class.new.perform(cluster.id, integration_name) }
            .to change { project.reload.prometheus_integration&.active }.from(nil).to(true)
        end
      end
    end
  end

  context 'when cluster does not exist' do
    it 'does not raise Record Not Found error' do
      expect { described_class.new.perform(0, 'ignored in this context') }.not_to raise_error
    end
  end
end
