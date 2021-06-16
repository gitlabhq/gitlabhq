# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Gcp::FinalizeCreationService, '#execute' do
  include GoogleApi::CloudPlatformHelpers
  include KubernetesHelpers

  let(:cluster) { create(:cluster, :project, :providing_by_gcp) }
  let(:provider) { cluster.provider }
  let(:platform) { cluster.platform }
  let(:endpoint) { '111.111.111.111' }
  let(:api_url) { 'https://' + endpoint }
  let(:secret_name) { 'gitlab-token' }
  let(:token) { 'sample-token' }
  let(:namespace) { "#{cluster.project.path}-#{cluster.project.id}" }

  subject { described_class.new.execute(provider) }

  shared_examples 'success' do
    it 'configures provider and kubernetes' do
      subject

      expect(provider).to be_created
    end

    it 'properly configures database models' do
      subject

      cluster.reload

      expect(provider.endpoint).to eq(endpoint)
      expect(platform.api_url).to eq(api_url)
      expect(platform.ca_cert).to eq(Base64.decode64(load_sample_cert).strip)
      expect(platform.token).to eq(token)
    end
  end

  shared_examples 'error' do
    it 'sets an error to provider object' do
      subject

      expect(provider.reload).to be_errored
    end
  end

  shared_examples 'kubernetes information not successfully fetched' do
    context 'when failed to fetch gke cluster info' do
      before do
        stub_cloud_platform_get_zone_cluster_error(provider.gcp_project_id, provider.zone, cluster.name)
      end

      it_behaves_like 'error'
    end

    context 'when token is empty' do
      let(:token) { '' }

      it_behaves_like 'error'
    end

    context 'when failed to fetch kubernetes token' do
      before do
        stub_kubeclient_get_secret_error(api_url, secret_name, namespace: 'default')
      end

      it_behaves_like 'error'
    end

    context 'when service account fails to create' do
      before do
        stub_kubeclient_create_service_account_error(api_url, namespace: 'default')
      end

      it_behaves_like 'error'
    end
  end

  shared_context 'kubernetes information successfully fetched' do
    before do
      stub_cloud_platform_get_zone_cluster(
        provider.gcp_project_id, provider.zone, cluster.name, { endpoint: endpoint }
      )

      stub_kubeclient_discover(api_url)
      stub_kubeclient_get_namespace(api_url)
      stub_kubeclient_create_namespace(api_url)
      stub_kubeclient_get_service_account_error(api_url, 'gitlab')
      stub_kubeclient_create_service_account(api_url)
      stub_kubeclient_create_secret(api_url)
      stub_kubeclient_put_secret(api_url, 'gitlab-token')

      stub_kubeclient_get_secret(
        api_url,
        metadata_name: secret_name,
        token: Base64.encode64(token),
        namespace: 'default'
      )

      stub_kubeclient_put_cluster_role_binding(api_url, 'gitlab-admin')
    end
  end

  context 'With a legacy ABAC cluster' do
    before do
      provider.legacy_abac = true
    end

    include_context 'kubernetes information successfully fetched'

    it_behaves_like 'success'

    it 'uses ABAC authorization type' do
      subject
      cluster.reload

      expect(platform).to be_abac
      expect(platform.authorization_type).to eq('abac')
    end

    it_behaves_like 'kubernetes information not successfully fetched'
  end

  context 'With an RBAC cluster' do
    before do
      provider.legacy_abac = false
    end

    include_context 'kubernetes information successfully fetched'

    it_behaves_like 'success'

    it 'uses RBAC authorization type' do
      subject
      cluster.reload

      expect(platform).to be_rbac
      expect(platform.authorization_type).to eq('rbac')
    end

    it_behaves_like 'kubernetes information not successfully fetched'
  end

  context 'With a Cloud Run cluster' do
    before do
      provider.cloud_run = true
    end

    include_context 'kubernetes information successfully fetched'

    it_behaves_like 'success'

    it 'has knative pre-installed' do
      subject
      cluster.reload

      expect(cluster.application_knative).to be_present
      expect(cluster.application_knative).to be_pre_installed
    end
  end
end
