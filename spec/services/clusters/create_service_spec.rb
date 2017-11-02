require 'spec_helper'

describe Clusters::CreateService do
  let(:access_token) { 'xxx' }
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:result) { described_class.new(project, user, params).execute(access_token) }

  context 'when provider is gcp' do
    context 'when correct params' do
      let(:params) do
        {
          name: 'test-cluster',
          platform_type: :kubernetes,
          provider_type: :gcp,
          platform_kubernetes_attributes: {
            namespace: 'custom-namespace'
          },
          provider_gcp_attributes: {
            gcp_project_id: 'gcp-project',
            zone: 'us-central1-a',
            num_nodes: 1,
            machine_type: 'machine_type-a'
          }
        }
      end

      it 'creates a cluster object and performs a worker' do
        expect(ClusterProvisionWorker).to receive(:perform_async)

        expect { result }
          .to change { Clusters::Cluster.count }.by(1)
          .and change { Clusters::Platforms::Kubernetes.count }.by(1)
          .and change { Clusters::Providers::Gcp.count }.by(1)

        expect(result.name).to eq('test-cluster')
        expect(result.user).to eq(user)
        expect(result.project).to eq(project)
        expect(result.provider.gcp_project_id).to eq('gcp-project')
        expect(result.provider.zone).to eq('us-central1-a')
        expect(result.provider.num_nodes).to eq(1)
        expect(result.provider.machine_type).to eq('machine_type-a')
        expect(result.provider.access_token).to eq(access_token)
        expect(result.platform.namespace).to eq('custom-namespace')
        expect(result.platform.api_url).to eq(Clusters::CreateService::TEMPOLARY_API_URL)
        expect(result.platform.token).to eq(Clusters::CreateService::TEMPOLARY_TOKEN)
      end
    end

    context 'when invalid params' do
      let(:params) do
        {
          name: 'test-cluster',
          platform_type: :kubernetes,
          provider_type: :gcp,
          platform_kubernetes_attributes: {
            namespace: 'custom-namespace'
          },
          provider_gcp_attributes: {
            gcp_project_id: '!!!!!!!',
            zone: 'us-central1-a',
            num_nodes: 1,
            machine_type: 'machine_type-a'
          }
        }
      end

      it 'returns an error' do
        expect(ClusterProvisionWorker).not_to receive(:perform_async)
        expect { result }.to change { Clusters::Cluster.count }.by(0)
        expect(result.errors[:"provider_gcp.gcp_project_id"]).to be_present
      end
    end
  end

  context 'when provider is user' do
    context 'when correct params' do
      let(:params) do
        {
          name: 'test-cluster',
          platform_type: :kubernetes,
          provider_type: :user,
          platform_kubernetes_attributes: {
            namespace: 'custom-namespace',
            api_url: 'https://111.111.111.111',
            token: 'token'
          }
        }
      end

      it 'creates a cluster object and performs a worker' do
        expect(ClusterProvisionWorker).to receive(:perform_async)

        expect { result }
          .to change { Clusters::Cluster.count }.by(1)
          .and change { Clusters::Platforms::Kubernetes.count }.by(1)

        expect(result.name).to eq('test-cluster')
        expect(result.user).to eq(user)
        expect(result.project).to eq(project)
        expect(result.provider).to be_nil
        expect(result.platform.namespace).to eq('custom-namespace')
      end
    end

    context 'when invalid params' do
      let(:params) do
        {
          name: 'test-cluster',
          platform_type: :kubernetes,
          provider_type: :user,
          platform_kubernetes_attributes: {
            namespace: 'custom-namespace',
            api_url: '!!!!!',
            token: 'token'
          }
        }
      end

      it 'returns an error' do
        # expect(ClusterProvisionWorker).not_to receive(:perform_async)
        expect { result }.to change { Clusters::Cluster.count }.by(0)
        expect(result.errors[:"platform_kubernetes.api_url"]).to be_present
      end
    end
  end
end
