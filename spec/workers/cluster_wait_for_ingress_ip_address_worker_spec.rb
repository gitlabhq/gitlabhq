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
      worker.perform('ingress', 117, 2)

      expect(service).to have_received(:execute)
    end

    context 'when the service succeeds' do
      it 'does not schedule another worker' do
        worker.perform('ingress', 117, 2)

        expect(described_class)
          .not_to have_received(:perform_in)
      end
    end

    context 'when the service fails' do
      before do
        allow(service)
          .to receive(:execute)
          .and_return(false)
      end

      context 'when there are retries remaining' do
        it 'schedules another worker with 1 less retry' do
          worker.perform('ingress', 117, 2)

          expect(described_class)
            .to have_received(:perform_in)
            .with(ClusterWaitForIngressIpAddressWorker::INTERVAL, 'ingress', 117, 1)
        end
      end

      context 'when there are no retries_remaining' do
        it 'does not schedule another worker' do
          worker.perform('ingress', 117, 0)

          expect(described_class)
            .not_to have_received(:perform_in)
        end
      end
    end

    context 'when the update raises exception' do
      before do
        allow(service)
          .to receive(:execute)
          .and_raise(Clusters::Applications::CheckIngressIpAddressService::Error, "something went wrong")
      end

      context 'when there are retries remaining' do
        it 'schedules another worker with 1 less retry and re-raises the error' do
          expect { worker.perform('ingress', 117, 2) }
            .to raise_error(Clusters::Applications::CheckIngressIpAddressService::Error, "something went wrong")

          expect(described_class)
            .to have_received(:perform_in)
            .with(ClusterWaitForIngressIpAddressWorker::INTERVAL, 'ingress', 117, 1)
        end
      end

      context 'when there are no retries_remaining' do
        it 'does not schedule another worker but re-raises the error' do
          expect { worker.perform('ingress', 117, 0) }
            .to raise_error(Clusters::Applications::CheckIngressIpAddressService::Error, "something went wrong")

          expect(described_class)
            .not_to have_received(:perform_in)
        end
      end
    end
  end
end
