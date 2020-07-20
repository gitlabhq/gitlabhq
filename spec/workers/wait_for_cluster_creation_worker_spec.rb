# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WaitForClusterCreationWorker do
  describe '#perform' do
    context 'when provider type is gcp' do
      let(:cluster) { create(:cluster, provider_type: :gcp, provider_gcp: provider) }
      let(:provider) { create(:cluster_provider_gcp, :creating) }

      it 'provisions a cluster' do
        expect_any_instance_of(Clusters::Gcp::VerifyProvisionStatusService).to receive(:execute).with(provider)

        described_class.new.perform(cluster.id)
      end
    end

    context 'when provider type is aws' do
      let(:cluster) { create(:cluster, provider_type: :aws, provider_aws: provider) }
      let(:provider) { create(:cluster_provider_aws, :creating) }

      it 'provisions a cluster' do
        expect_any_instance_of(Clusters::Aws::VerifyProvisionStatusService).to receive(:execute).with(provider)

        described_class.new.perform(cluster.id)
      end
    end

    context 'when provider type is user' do
      let(:cluster) { create(:cluster, provider_type: :user) }

      it 'does not provision a cluster' do
        expect_any_instance_of(Clusters::Gcp::VerifyProvisionStatusService).not_to receive(:execute)

        described_class.new.perform(cluster.id)
      end
    end

    context 'when cluster does not exist' do
      it 'does not provision a cluster' do
        expect_any_instance_of(Clusters::Gcp::VerifyProvisionStatusService).not_to receive(:execute)

        described_class.new.perform(123)
      end
    end
  end
end
