require 'spec_helper'

describe Clusters::Applications::CheckIngressIpAddressService do
  include ExclusiveLeaseHelpers

  let(:application) { create(:clusters_applications_ingress, :installed) }
  let(:service) { described_class.new(application) }
  let(:kubeclient) { double(::Kubeclient::Client, get_service: kube_service) }
  let(:ingress) { [{ ip: '111.222.111.222' }] }
  let(:lease_key) { "check_ingress_ip_address_service:#{application.id}" }

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
    stub_exclusive_lease(lease_key, timeout: 15.seconds.to_i)
    allow(application.cluster).to receive(:kubeclient).and_return(kubeclient)
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
      it 'does not call kubeclient' do
        stub_exclusive_lease_taken(lease_key, timeout: 15.seconds.to_i)

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
