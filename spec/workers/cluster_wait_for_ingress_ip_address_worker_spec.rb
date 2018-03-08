require 'spec_helper'

describe ClusterWaitForIngressIpAddressWorker do
  describe '#perform' do
    let(:service) { instance_double(Clusters::Applications::CheckIngressIpAddressService, execute: true) }
    let(:application) { instance_double(Clusters::Applications::Ingress) }
    let(:worker) { described_class.new }

    before do
      allow(worker)
        .to receive(:find_application)
        .with('ingress', 117)
        .and_yield(application)

      allow(Clusters::Applications::CheckIngressIpAddressService)
        .to receive(:new)
        .with(application)
        .and_return(service)

      allow(described_class)
        .to receive(:perform_in)
    end

    it 'finds the application and calls CheckIngressIpAddressService#execute' do
      worker.perform('ingress', 117)

      expect(service).to have_received(:execute)
    end
  end
end
