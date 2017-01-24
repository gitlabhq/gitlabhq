require 'spec_helper'

describe ReactiveCachingWorker do
  let(:project) { create(:kubernetes_project) }
  let(:service) { project.deployment_service }
  subject { described_class.new.perform("KubernetesService", service.id) }

  describe '#perform' do
    it 'calls #exclusively_update_reactive_cache!' do
      expect_any_instance_of(KubernetesService).to receive(:exclusively_update_reactive_cache!)

      subject
    end
  end
end
