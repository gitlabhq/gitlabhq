require 'spec_helper'

describe ClusterWaitForIngressIpAddressWorker do
  describe '#perform' do
    let(:service) { instance_double(Clusters::Applications::CheckIngressIpAddressService) }
    let(:application) { instance_double(Clusters::Applications::Ingress) }
    let(:worker) { described_class.new }

    it 'finds the application and calls CheckIngressIpAddressService#execute' do
      expect(worker).to receive(:find_application).with('ingress', 117).and_yield(application)
      expect(Clusters::Applications::CheckIngressIpAddressService)
        .to receive(:new)
        .with(application)
        .and_return(service)
      expect(service).to receive(:execute).with(2)

      worker.perform('ingress', 117, 2)
    end
  end
end
