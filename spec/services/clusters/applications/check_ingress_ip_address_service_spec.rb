require 'spec_helper'

describe Clusters::Applications::CheckIngressIpAddressService do
  let(:application) { create(:clusters_applications_ingress, :installed) }
  let(:service) { described_class.new(application) }
  let(:kubeclient) { double(::Kubeclient::Client, get_service: kube_service) }
  let(:ingress) { [{ ip: '111.222.111.222' }] }
  let(:exclusive_lease) { instance_double(Gitlab::ExclusiveLease, try_obtain: true) }

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

  subject { service.execute }

  before do
    allow(application.cluster).to receive(:kubeclient).and_return(kubeclient)
    allow(Gitlab::ExclusiveLease)
      .to receive(:new)
      .with("check_ingress_ip_address_service:#{application.id}", timeout: 15.seconds.to_i)
      .and_return(exclusive_lease)
  end

  describe '#execute' do
    context 'when the ingress ip address is available' do
      it 'updates the external_ip for the app' do
        subject

        expect(application.external_ip).to eq('111.222.111.222')
      end
    end

    context 'when the ingress ip address is not available' do
      let(:ingress) { nil }

      it 'does not error' do
        subject
      end
    end

    context 'when the exclusive lease cannot be obtained' do
      before do
        allow(exclusive_lease)
          .to receive(:try_obtain)
          .and_return(false)
      end

      it 'does not call kubeclient' do
        subject

        expect(kubeclient).not_to have_received(:get_service)
      end
    end

    context 'when there is already an external_ip' do
      let(:application) { create(:clusters_applications_ingress, :installed, external_ip: '001.111.002.111') }

      it 'does not call kubeclient' do
        subject

        expect(kubeclient).not_to have_received(:get_service)
      end
    end
  end
end
