require 'spec_helper'

describe Clusters::Gcp::ProvisionService do
  include GoogleApi::CloudPlatformHelpers

  describe '#execute' do
    let(:provider) { create(:cluster_provider_gcp, :scheduled) }
    let(:gcp_project_id) { provider.gcp_project_id }
    let(:zone) { provider.zone }

    shared_examples 'success' do
      it 'schedules a worker for status minitoring' do
        expect(WaitForClusterCreationWorker).to receive(:perform_in)

        described_class.new.execute(provider)

        expect(provider.reload).to be_creating
      end
    end

    shared_examples 'error' do
      it 'sets an error to provider object' do
        described_class.new.execute(provider)

        expect(provider.reload).to be_errored
      end
    end

    context 'when suceeded to request provision' do
      before do
        stub_cloud_platform_create_cluster(gcp_project_id, zone)
      end

      it_behaves_like 'success'
    end

    context 'when operation status is unexpected' do
      before do
        stub_cloud_platform_create_cluster(
          gcp_project_id, zone,
          {
            "status": 'unexpected'
          } )
      end

      it_behaves_like 'error'
    end

    context 'when selfLink is unexpected' do
      before do
        stub_cloud_platform_create_cluster(
          gcp_project_id, zone,
          {
            "selfLink": 'unexpected'
          })
      end

      it_behaves_like 'error'
    end

    context 'when Internal Server Error happened' do
      before do
        stub_cloud_platform_create_cluster_error(gcp_project_id, zone)
      end

      it_behaves_like 'error'
    end
  end
end
