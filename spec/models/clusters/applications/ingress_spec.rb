require 'rails_helper'

describe Clusters::Applications::Ingress do
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to validate_presence_of(:cluster) }

  before do
    allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_in)
  end

  include_examples 'cluster application specs', described_class

  describe '#make_installed!' do
    before do
      application.make_installed!
    end

    let(:application) { create(:clusters_applications_ingress, :installing) }

    it 'schedules a ClusterWaitForIngressIpAddressWorker' do
      expect(ClusterWaitForIngressIpAddressWorker).to have_received(:perform_in)
        .with(ClusterWaitForIngressIpAddressWorker::INTERVAL, 'ingress', application.id, 3)
    end
  end
end
