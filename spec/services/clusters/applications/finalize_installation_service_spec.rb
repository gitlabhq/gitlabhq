require 'spec_helper'

describe Clusters::Applications::FinalizeInstallationService do
  describe '#execute' do
    let(:application) { create(:applications_helm, :installing) }
    let(:service) { described_class.new(application) }

    before do
      expect_any_instance_of(Gitlab::Kubernetes::Helm).to receive(:delete_installation_pod!).with(application)
    end

    context 'when installation POD succeeded' do
      it 'make the application installed' do
        service.execute

        expect(application).to be_installed
        expect(application.status_reason).to be_nil
      end
    end

    context 'when installation POD failed' do
      let(:application) { create(:applications_helm, :errored) }

      it 'make the application errored' do
        service.execute

        expect(application).to be_errored
        expect(application.status_reason).not_to be_nil
      end
    end
  end
end
