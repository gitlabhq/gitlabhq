require 'spec_helper'

describe Clusters::Applications::CheckIngressIpAddressService do
  let(:application) { create(:clusters_applications_ingress, :installed) }
  let(:service) { described_class.new(application) }
  let(:kube_service) do
    ::Kubeclient::Resource.new(
      {
          status: {
              loadBalancer: {
                  ingress: ingress
              }
          }
      }
    )
  end
  let(:kubeclient) { double(::Kubeclient::Client, get_service: kube_service) }
  let(:ingress) { [{ ip: '111.222.111.222' }] }

  before do
    allow(application.cluster).to receive(:kubeclient).and_return(kubeclient)
  end

  describe '#execute' do
    context 'when the ingress ip address is available' do
      it 'updates the external_ip for the app and does not schedule another worker' do
        expect(ClusterWaitForIngressIpAddressWorker).not_to receive(:perform_in)

        service.execute(1)

        expect(application.external_ip).to eq('111.222.111.222')
      end
    end

    context 'when the ingress ip address is not available' do
      let(:ingress) { nil }

      it 'it schedules another worker with 1 less retry' do
        expect(ClusterWaitForIngressIpAddressWorker)
          .to receive(:perform_in)
          .with(ClusterWaitForIngressIpAddressWorker::INTERVAL, 'ingress', application.id, 0)

        service.execute(1)
      end

      context 'when no more retries remaining' do
        it 'does not schedule another worker' do
          expect(ClusterWaitForIngressIpAddressWorker).not_to receive(:perform_in)

          service.execute(0)
        end
      end
    end

    context 'when there is already an external_ip' do
      let(:application) { create(:clusters_applications_ingress, :installed, external_ip: '001.111.002.111') }

      it 'does nothing' do
        expect(kubeclient).not_to receive(:get_service)

        service.execute(1)

        expect(application.external_ip).to eq('001.111.002.111')
      end
    end

    context 'when a kubernetes error occurs' do
      before do
        allow(kubeclient).to receive(:get_service).and_raise(KubeException.new(500, 'something blew up', nil))
      end

      it 'it schedules another worker with 1 less retry' do
        expect(ClusterWaitForIngressIpAddressWorker)
          .to receive(:perform_in)
          .with(ClusterWaitForIngressIpAddressWorker::INTERVAL, 'ingress', application.id, 0)

        service.execute(1)
      end
    end
  end
end
