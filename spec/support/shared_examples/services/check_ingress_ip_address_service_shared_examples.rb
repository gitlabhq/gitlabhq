# frozen_string_literal: true

RSpec.shared_examples 'check ingress ip executions' do |app_name|
  describe '#execute' do
    let(:application) { create(app_name, :installed) }
    let(:service) { described_class.new(application) }
    let(:kubeclient) { double(::Kubeclient::Client, get_service: kube_service) }

    context 'when the ingress ip address is available' do
      it 'updates the external_ip for the app' do
        subject

        expect(application.external_ip).to eq('111.222.111.222')
      end
    end

    context 'when the ingress external hostname is available' do
      it 'updates the external_hostname for the app' do
        subject

        expect(application.external_hostname).to eq('localhost.localdomain')
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
  end
end
