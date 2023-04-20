# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Applications::DeactivateIntegrationWorker, '#perform', feature_category: :deployment_management do
  context 'when cluster exists' do
    describe 'prometheus integration' do
      let(:integration_name) { 'prometheus' }
      let!(:integration) { create(:clusters_integrations_prometheus, cluster: cluster) }

      context 'when prometheus integration exists' do
        let!(:prometheus_integration) do
          create(:prometheus_integration, project: project, manual_configuration: false, active: true)
        end

        before do
          integration.delete # prometheus integration before save synchronises active stated with integration existence.
        end

        context 'with cluster type: group' do
          let(:group) { create(:group) }
          let(:project) { create(:project, group: group) }
          let(:cluster) { create(:cluster_for_group, groups: [group]) }

          it 'ensures Prometheus integration is deactivated' do
            expect { described_class.new.perform(cluster.id, integration_name) }
              .to change { prometheus_integration.reload.active }.from(true).to(false)
          end
        end

        context 'with cluster type: project' do
          let(:project) { create(:project) }
          let(:cluster) { create(:cluster, projects: [project]) }

          it 'ensures Prometheus integration is deactivated' do
            expect { described_class.new.perform(cluster.id, integration_name) }
              .to change { prometheus_integration.reload.active }.from(true).to(false)
          end
        end

        context 'with cluster type: instance' do
          let(:project) { create(:project) }
          let(:cluster) { create(:cluster, :instance) }

          it 'ensures Prometheus integration is deactivated' do
            expect { described_class.new.perform(cluster.id, integration_name) }
              .to change { prometheus_integration.reload.active }.from(true).to(false)
          end
        end
      end

      context 'when prometheus integration does not exist' do
        context 'with cluster type: project' do
          let(:project) { create(:project) }
          let(:cluster) { create(:cluster, projects: [project]) }

          it 'does not raise errors' do
            expect { described_class.new.perform(cluster.id, integration_name) }.not_to raise_error
          end
        end
      end
    end
  end

  context 'when cluster does not exist' do
    it 'raises Record Not Found error' do
      expect { described_class.new.perform(0, 'ignored in this context') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
