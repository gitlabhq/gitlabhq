# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Aws::FinalizeCreationService do
  describe '#execute' do
    let(:provider) { create(:cluster_provider_aws, :creating) }
    let(:platform) { provider.cluster.platform_kubernetes }

    let(:create_service_account_service) { double(execute: true) }
    let(:fetch_token_service) { double(execute: gitlab_token) }
    let(:kube_client) { double(create_config_map: true) }
    let(:cluster_stack) { double(outputs: [endpoint_output, cert_output, node_role_output]) }
    let(:node_auth_config_map) { double }

    let(:endpoint_output) { double(output_key: 'ClusterEndpoint', output_value: api_url) }
    let(:cert_output) { double(output_key: 'ClusterCertificate', output_value: Base64.encode64(ca_pem)) }
    let(:node_role_output) { double(output_key: 'NodeInstanceRole', output_value: node_role) }

    let(:api_url) { 'https://kubernetes.example.com' }
    let(:ca_pem) { File.read(Rails.root.join('spec/fixtures/clusters/sample_cert.pem')) }
    let(:gitlab_token) { 'gitlab-token' }
    let(:iam_token) { 'iam-token' }
    let(:node_role) { 'arn::aws::iam::123456789012:role/node-role' }

    subject { described_class.new.execute(provider) }

    before do
      allow(Clusters::Kubernetes::CreateOrUpdateServiceAccountService).to receive(:gitlab_creator)
        .with(kube_client, rbac: true)
        .and_return(create_service_account_service)

      allow(Clusters::Kubernetes::FetchKubernetesTokenService).to receive(:new)
        .with(
          kube_client,
          Clusters::Kubernetes::GITLAB_ADMIN_TOKEN_NAME,
          Clusters::Kubernetes::GITLAB_SERVICE_ACCOUNT_NAMESPACE)
        .and_return(fetch_token_service)

      allow(Gitlab::Kubernetes::KubeClient).to receive(:new)
        .with(
          api_url,
          auth_options: { bearer_token: iam_token },
          ssl_options: {
            verify_ssl: OpenSSL::SSL::VERIFY_PEER,
            cert_store: instance_of(OpenSSL::X509::Store)
          },
          http_proxy_uri: nil
        )
        .and_return(kube_client)

      allow(provider.api_client).to receive(:describe_stacks)
        .with(stack_name: provider.cluster.name)
        .and_return(double(stacks: [cluster_stack]))

      allow(Kubeclient::AmazonEksCredentials).to receive(:token)
        .with(provider.credentials, provider.cluster.name)
        .and_return(iam_token)

      allow(Gitlab::Kubernetes::ConfigMaps::AwsNodeAuth).to receive(:new)
        .with(node_role).and_return(double(generate: node_auth_config_map))
    end

    it 'configures the provider and platform' do
      subject

      expect(provider).to be_created
      expect(platform.api_url).to eq(api_url)
      expect(platform.ca_pem).to eq(ca_pem)
      expect(platform.token).to eq(gitlab_token)
      expect(platform).to be_rbac
    end

    it 'calls the create_service_account_service' do
      expect(create_service_account_service).to receive(:execute).once

      subject
    end

    it 'configures cluster node authentication' do
      expect(kube_client).to receive(:create_config_map).with(node_auth_config_map).once

      subject
    end

    describe 'error handling' do
      shared_examples 'provision error' do |message|
        it "sets the status to :errored with an appropriate error message" do
          subject

          expect(provider).to be_errored
          expect(provider.status_reason).to include(message)
        end
      end

      context 'failed to request stack details from AWS' do
        before do
          allow(provider.api_client).to receive(:describe_stacks)
            .and_raise(Aws::CloudFormation::Errors::ServiceError.new(double, "Error message"))
        end

        include_examples 'provision error', 'Failed to fetch CloudFormation stack'
      end

      context 'failed to create auth config map' do
        before do
          allow(kube_client).to receive(:create_config_map)
            .and_raise(Kubeclient::HttpError.new(500, 'Error', nil))
        end

        include_examples 'provision error', 'Failed to run Kubeclient'
      end

      context 'failed to save records' do
        before do
          allow(provider.cluster).to receive(:save!)
            .and_raise(ActiveRecord::RecordInvalid)
        end

        include_examples 'provision error', 'Failed to configure EKS provider'
      end
    end
  end
end
