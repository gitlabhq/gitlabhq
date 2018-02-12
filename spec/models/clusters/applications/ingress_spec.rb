require 'rails_helper'

describe Clusters::Applications::Ingress do
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to validate_presence_of(:cluster) }

  include_examples 'cluster application specs', described_class

  describe '#post_install' do
    let(:application) { create(:clusters_applications_ingress, :installed) }

    before do
      allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_in)
      application.post_install
    end

    it 'schedules a ClusterWaitForIngressIpAddressWorker' do
      expect(ClusterWaitForIngressIpAddressWorker).to have_received(:perform_in)
        .with(ClusterWaitForIngressIpAddressWorker::INTERVAL, 'ingress', application.id, 3)
    end
  end
end
