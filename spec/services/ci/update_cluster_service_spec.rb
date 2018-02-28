require 'spec_helper'

describe Ci::UpdateClusterService do
  describe '#execute' do
    let(:cluster) { create(:gcp_cluster, :created_on_gke, :with_kubernetes_service) }

    before do
      described_class.new(cluster.project, cluster.user, params).execute(cluster)

      cluster.reload
    end

    context 'when correct params' do
      context 'when enabled is true' do
        let(:params) { { 'enabled' => 'true' } }

        it 'enables cluster and overwrite kubernetes service' do
          expect(cluster.enabled).to be_truthy
          expect(cluster.service.active).to be_truthy
          expect(cluster.service.api_url).to eq(cluster.api_url)
          expect(cluster.service.ca_pem).to eq(cluster.ca_cert)
          expect(cluster.service.namespace).to eq(cluster.project_namespace)
          expect(cluster.service.token).to eq(cluster.kubernetes_token)
        end
      end

      context 'when enabled is false' do
        let(:params) { { 'enabled' => 'false' } }

        it 'disables cluster and kubernetes service' do
          expect(cluster.enabled).to be_falsy
          expect(cluster.service.active).to be_falsy
        end
      end
    end
  end
end
