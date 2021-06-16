# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GoogleApi::CloudPlatform::Client do
  let(:token) { 'token' }
  let(:client) { described_class.new(token, nil) }
  let(:user_agent_options) { client.instance_eval { user_agent_header } }

  describe '.session_key_for_redirect_uri' do
    let(:state) { 'random_string' }

    subject { described_class.session_key_for_redirect_uri(state) }

    it 'creates a new session key' do
      is_expected.to eq('cloud_platform_second_redirect_uri_random_string')
    end
  end

  describe '.new_session_key_for_redirect_uri' do
    it 'generates a new session key' do
      expect { |b| described_class.new_session_key_for_redirect_uri(&b) }
        .to yield_with_args(String)
    end
  end

  describe '#validate_token' do
    subject { client.validate_token(expires_at) }

    let(:expires_at) { 1.hour.since.utc.strftime('%s') }

    context 'when token is nil' do
      let(:token) { nil }

      it { is_expected.to be_falsy }
    end

    context 'when expires_at is nil' do
      let(:expires_at) { nil }

      it { is_expected.to be_falsy }
    end

    context 'when expires in 1 hour' do
      it { is_expected.to be_truthy }
    end

    context 'when expires in 10 minutes' do
      let(:expires_at) { 5.minutes.since.utc.strftime('%s') }

      it { is_expected.to be_falsy }
    end
  end

  describe '#projects_zones_clusters_get' do
    subject { client.projects_zones_clusters_get(spy, spy, spy) }

    let(:gke_cluster) { double }

    before do
      allow_any_instance_of(Google::Apis::ContainerV1::ContainerService)
        .to receive(:get_zone_cluster).with(any_args, options: user_agent_options)
        .and_return(gke_cluster)
    end

    it { is_expected.to eq(gke_cluster) }
  end

  describe '#projects_zones_clusters_create' do
    subject do
      client.projects_zones_clusters_create(
        project_id, zone, cluster_name, cluster_size, machine_type: machine_type, legacy_abac: legacy_abac, enable_addons: enable_addons)
    end

    let(:project_id) { 'project-123' }
    let(:zone) { 'us-central1-a' }
    let(:cluster_name) { 'test-cluster' }
    let(:cluster_size) { 1 }
    let(:machine_type) { 'n1-standard-2' }
    let(:legacy_abac) { true }
    let(:enable_addons) { [] }

    let(:addons_config) do
      enable_addons.each_with_object({}) do |addon, hash|
        hash[addon] = { disabled: false }
      end
    end

    let(:cluster_options) do
      {
        cluster: {
          name: cluster_name,
          initial_node_count: cluster_size,
          node_config: {
            machine_type: machine_type,
            oauth_scopes: [
              "https://www.googleapis.com/auth/devstorage.read_only",
              "https://www.googleapis.com/auth/logging.write",
              "https://www.googleapis.com/auth/monitoring"
            ]
          },
          master_auth: {
            client_certificate_config: {
              issue_client_certificate: true
            }
          },
          legacy_abac: {
            enabled: legacy_abac
          },
          ip_allocation_policy: {
            use_ip_aliases: true,
            cluster_ipv4_cidr_block: '/16'
          },
          addons_config: addons_config
        }
      }
    end

    let(:create_cluster_request_body) { double('Google::Apis::ContainerV1beta1::CreateClusterRequest') }
    let(:operation) { double }

    before do
      allow_any_instance_of(Google::Apis::ContainerV1beta1::ContainerService)
        .to receive(:create_cluster).with(any_args)
        .and_return(operation)
    end

    it 'sets corresponded parameters' do
      expect_any_instance_of(Google::Apis::ContainerV1beta1::ContainerService)
        .to receive(:create_cluster).with(project_id, zone, create_cluster_request_body, options: user_agent_options)

      expect(Google::Apis::ContainerV1beta1::CreateClusterRequest)
        .to receive(:new).with(cluster_options).and_return(create_cluster_request_body)

      expect(subject).to eq operation
    end

    context 'create without legacy_abac' do
      let(:legacy_abac) { false }

      it 'sets corresponded parameters' do
        expect_any_instance_of(Google::Apis::ContainerV1beta1::ContainerService)
          .to receive(:create_cluster).with(project_id, zone, create_cluster_request_body, options: user_agent_options)

        expect(Google::Apis::ContainerV1beta1::CreateClusterRequest)
          .to receive(:new).with(cluster_options).and_return(create_cluster_request_body)

        expect(subject).to eq operation
      end
    end

    context 'create with enable_addons for cloud_run' do
      let(:enable_addons) { [:http_load_balancing, :istio_config, :cloud_run_config] }

      it 'sets corresponded parameters' do
        expect_any_instance_of(Google::Apis::ContainerV1beta1::ContainerService)
          .to receive(:create_cluster).with(project_id, zone, create_cluster_request_body, options: user_agent_options)

        expect(Google::Apis::ContainerV1beta1::CreateClusterRequest)
          .to receive(:new).with(cluster_options).and_return(create_cluster_request_body)

        expect(subject).to eq operation
      end
    end
  end

  describe '#projects_zones_operations' do
    subject { client.projects_zones_operations(spy, spy, spy) }

    let(:operation) { double }

    before do
      allow_any_instance_of(Google::Apis::ContainerV1::ContainerService)
        .to receive(:get_zone_operation).with(any_args, options: user_agent_options)
        .and_return(operation)
    end

    it { is_expected.to eq(operation) }
  end

  describe '#parse_operation_id' do
    subject { client.parse_operation_id(self_link) }

    context 'when expected url' do
      let(:self_link) do
        'projects/gcp-project-12345/zones/us-central1-a/operations/ope-123'
      end

      it { is_expected.to eq('ope-123') }
    end

    context 'when unexpected url' do
      let(:self_link) { '???' }

      it { is_expected.to be_nil }
    end
  end

  describe '#user_agent_header' do
    subject { client.instance_eval { user_agent_header } }

    it 'returns a RequestOptions object' do
      expect(subject).to be_instance_of(Google::Apis::RequestOptions)
    end

    it 'has the correct GitLab version in User-Agent header' do
      stub_const('Gitlab::VERSION', '10.3.0-pre')

      expect(subject.header).to eq({ 'User-Agent': 'GitLab/10.3 (GPN:GitLab;)' })
    end
  end
end
