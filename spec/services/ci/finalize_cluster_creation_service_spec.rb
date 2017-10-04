require 'spec_helper'

describe Ci::FinalizeClusterCreationService do
  describe '#execute' do
    let(:cluster) { create(:gcp_cluster) }
    let(:result) { described_class.new.execute(cluster) }

    context 'when suceeded to get cluster from api' do
      let(:gke_cluster) { double }

      before do
        allow(gke_cluster).to receive(:endpoint).and_return('111.111.111.111')
        allow(gke_cluster).to receive(:master_auth).and_return(spy)
        allow_any_instance_of(GoogleApi::CloudPlatform::Client)
          .to receive(:projects_zones_clusters_get).and_return(gke_cluster)
      end

      context 'when suceeded to get kubernetes token' do
        let(:kubernetes_token) { 'abc' }

        before do
          allow_any_instance_of(Ci::FetchKubernetesTokenService)
            .to receive(:execute).and_return(kubernetes_token)
        end

        it 'executes integration cluster' do
          expect_any_instance_of(Ci::IntegrateClusterService).to receive(:execute)
          described_class.new.execute(cluster)
        end
      end

      context 'when failed to get kubernetes token' do
        before do
          allow_any_instance_of(Ci::FetchKubernetesTokenService)
            .to receive(:execute).and_return(nil)
        end

        it 'sets an error to cluster object' do
          described_class.new.execute(cluster)

          expect(cluster.reload).to be_errored
        end
      end
    end

    context 'when failed to get cluster from api' do
      let(:error) { Google::Apis::ServerError.new('a') }

      before do
        allow_any_instance_of(GoogleApi::CloudPlatform::Client)
          .to receive(:projects_zones_clusters_get).and_raise(error)
      end

      it 'sets an error to cluster object' do
        described_class.new.execute(cluster)

        expect(cluster.reload).to be_errored
      end
    end
  end
end
