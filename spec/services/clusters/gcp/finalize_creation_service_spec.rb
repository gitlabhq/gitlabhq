require 'spec_helper'

describe Clusters::Gcp::FinalizeCreationService do
  include GoogleApi::CloudPlatformHelpers
  include KubernetesHelpers

  describe '#execute' do
    let(:cluster) { create(:cluster, :project, :providing_by_gcp) }
    let(:provider) { cluster.provider }
    let(:platform) { cluster.platform }
    let(:gcp_project_id) { provider.gcp_project_id }
    let(:zone) { provider.zone }
    let(:cluster_name) { cluster.name }

    shared_examples 'success' do
      it 'configures provider and kubernetes' do
        described_class.new.execute(provider)

        expect(provider).to be_created
      end
    end

    shared_examples 'error' do
      it 'sets an error to provider object' do
        described_class.new.execute(provider)

        expect(provider.reload).to be_errored
      end
    end

    context 'when suceeded to fetch gke cluster info' do
      let(:endpoint) { '111.111.111.111' }
      let(:api_url) { 'https://' + endpoint }
      let(:username) { 'sample-username' }
      let(:password) { 'sample-password' }

      before do
        stub_cloud_platform_get_zone_cluster(
          gcp_project_id, zone, cluster_name,
          {
            endpoint: endpoint,
            username: username,
            password: password
          }
        )

        stub_kubeclient_discover(api_url)
      end

      context 'when suceeded to fetch kuberenetes token' do
        let(:token) { 'sample-token' }

        before do
          stub_kubeclient_get_secrets(
            api_url,
            {
              token: Base64.encode64(token)
            } )
        end

        it_behaves_like 'success'

        it 'has corresponded data' do
          described_class.new.execute(provider)
          cluster.reload
          provider.reload
          platform.reload

          expect(provider.endpoint).to eq(endpoint)
          expect(platform.api_url).to eq(api_url)
          expect(platform.ca_cert).to eq(Base64.decode64(load_sample_cert))
          expect(platform.username).to eq(username)
          expect(platform.password).to eq(password)
          expect(platform.token).to eq(token)
        end
      end

      context 'when default-token is not found' do
        before do
          stub_kubeclient_get_secrets(api_url, metadata_name: 'aaaa')
        end

        it_behaves_like 'error'
      end

      context 'when token is empty' do
        before do
          stub_kubeclient_get_secrets(api_url, token: '')
        end

        it_behaves_like 'error'
      end

      context 'when failed to fetch kuberenetes token' do
        before do
          stub_kubeclient_get_secrets_error(api_url)
        end

        it_behaves_like 'error'
      end
    end

    context 'when failed to fetch gke cluster info' do
      before do
        stub_cloud_platform_get_zone_cluster_error(gcp_project_id, zone, cluster_name)
      end

      it_behaves_like 'error'
    end
  end
end
