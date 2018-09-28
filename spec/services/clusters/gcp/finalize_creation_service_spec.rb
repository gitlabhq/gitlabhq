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

    subject { described_class.new.execute(provider) }

    shared_examples 'success' do
      it 'configures provider and kubernetes' do
        subject

        expect(provider).to be_created
      end
    end

    shared_examples 'error' do
      it 'sets an error to provider object' do
        subject

        expect(provider.reload).to be_errored
      end
    end

    context 'when suceeded to fetch gke cluster info' do
      let(:endpoint) { '111.111.111.111' }
      let(:api_url) { 'https://' + endpoint }
      let(:username) { 'sample-username' }
      let(:password) { 'sample-password' }
      let(:secret_name) { 'gitlab-token' }

      before do
        stub_cloud_platform_get_zone_cluster(
          gcp_project_id, zone, cluster_name,
          {
            endpoint: endpoint,
            username: username,
            password: password
          }
        )
      end

      context 'service account and token created' do
        before do
          stub_kubeclient_discover(api_url)
          stub_kubeclient_create_service_account(api_url)
          stub_kubeclient_create_secret(api_url)
        end

        shared_context 'kubernetes token successfully fetched' do
          let(:token) { 'sample-token' }

          before do
            stub_kubeclient_get_secret(
              api_url,
              {
                metadata_name: secret_name,
                token: Base64.encode64(token)
              } )
          end
        end

        context 'provider legacy_abac is enabled' do
          include_context 'kubernetes token successfully fetched'

          it_behaves_like 'success'

          it 'properly configures database models' do
            subject

            cluster.reload

            expect(provider.endpoint).to eq(endpoint)
            expect(platform.api_url).to eq(api_url)
            expect(platform.ca_cert).to eq(Base64.decode64(load_sample_cert))
            expect(platform.username).to eq(username)
            expect(platform.password).to eq(password)
            expect(platform).to be_abac
            expect(platform.authorization_type).to eq('abac')
            expect(platform.token).to eq(token)
          end
        end

        context 'provider legacy_abac is disabled' do
          before do
            provider.legacy_abac = false
          end

          include_context 'kubernetes token successfully fetched'

          context 'cluster role binding created' do
            before do
              stub_kubeclient_create_cluster_role_binding(api_url)
            end

            it_behaves_like 'success'

            it 'properly configures database models' do
              subject

              cluster.reload

              expect(provider.endpoint).to eq(endpoint)
              expect(platform.api_url).to eq(api_url)
              expect(platform.ca_cert).to eq(Base64.decode64(load_sample_cert))
              expect(platform.username).to eq(username)
              expect(platform.password).to eq(password)
              expect(platform).to be_rbac
              expect(platform.token).to eq(token)
            end
          end
        end

        context 'when token is empty' do
          before do
            stub_kubeclient_get_secret(api_url, token: '', metadata_name: secret_name)
          end

          it_behaves_like 'error'
        end

        context 'when failed to fetch kubernetes token' do
          before do
            stub_kubeclient_get_secret_error(api_url, secret_name)
          end

          it_behaves_like 'error'
        end

        context 'when service account fails to create' do
          before do
            stub_kubeclient_create_service_account_error(api_url)
          end

          it_behaves_like 'error'
        end
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
