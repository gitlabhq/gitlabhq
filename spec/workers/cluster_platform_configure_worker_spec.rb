# frozen_string_literal: true

require 'spec_helper'

describe ClusterPlatformConfigureWorker do
  describe '#perform' do
    context 'when provider type is gcp' do
      let(:cluster) { create(:cluster, :provided_by_gcp) }

      it 'configures kubernetes platform' do
        expect_any_instance_of(Clusters::Kubernetes::ConfigureService).to receive(:execute).and_call_original

        described_class.new.perform(cluster.id)
      end
    end

    context 'when provider type is user' do
      let(:cluster) { create(:cluster, :provided_by_user) }

      it 'configures kubernetes platform' do
        expect_any_instance_of(Clusters::Kubernetes::ConfigureService).to receive(:execute).and_call_original

        described_class.new.perform(cluster.id)
      end
    end

    context 'when cluster does not exist' do
      it 'does not provision a cluster' do
        expect_any_instance_of(Clusters::Kubernetes::ConfigureService).not_to receive(:execute)

        described_class.new.perform(123)
      end
    end
  end
end
