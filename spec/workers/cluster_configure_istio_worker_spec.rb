# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClusterConfigureIstioWorker do
  describe '#perform' do
    shared_examples 'configure istio service' do
      it 'configures istio' do
        expect_any_instance_of(Clusters::Kubernetes::ConfigureIstioIngressService).to receive(:execute)

        described_class.new.perform(cluster.id)
      end
    end

    context 'when provider type is gcp' do
      let(:cluster) { create(:cluster, :project, :provided_by_gcp) }

      it_behaves_like 'configure istio service'
    end

    context 'when provider type is aws' do
      let(:cluster) { create(:cluster, :project, :provided_by_aws) }

      it_behaves_like 'configure istio service'
    end

    context 'when provider type is user' do
      let(:cluster) { create(:cluster, :project, :provided_by_user) }

      it_behaves_like 'configure istio service'
    end

    context 'when cluster does not exist' do
      it 'does not provision a cluster' do
        expect_any_instance_of(Clusters::Kubernetes::ConfigureIstioIngressService).not_to receive(:execute)

        described_class.new.perform(123)
      end
    end
  end
end
