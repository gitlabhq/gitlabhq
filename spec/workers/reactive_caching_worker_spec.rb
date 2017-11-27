require 'spec_helper'

describe ReactiveCachingWorker do
  let(:service) { project.deployment_service }
  subject { described_class.new.perform("KubernetesService", service.id) }

  describe '#perform' do
    shared_examples 'correct behavior with perform' do
      it 'calls #exclusively_update_reactive_cache!' do
        expect_any_instance_of(KubernetesService).to receive(:exclusively_update_reactive_cache!)

        subject
      end
    end

    context 'when user configured kubernetes from Integration > Kubernetes' do
      let(:project) { create(:kubernetes_project) }

      it_behaves_like 'correct behavior with perform'
    end

    context 'when user configured kubernetes from CI/CD > Clusters' do
      let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
      let(:project) { cluster.project }

      it_behaves_like 'correct behavior with perform'
    end
  end
end
