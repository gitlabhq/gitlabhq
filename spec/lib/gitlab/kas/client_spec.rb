# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kas::Client do
  let_it_be(:project) { create(:project) }
  let_it_be(:agent) { create(:cluster_agent, project: project) }

  describe '#initialize' do
    context 'kas is not enabled' do
      before do
        allow(Gitlab::Kas).to receive(:enabled?).and_return(false)
      end

      it 'raises a configuration error' do
        expect { described_class.new }.to raise_error(described_class::ConfigurationError, 'GitLab KAS is not enabled')
      end
    end

    context 'internal url is not set' do
      before do
        allow(Gitlab::Kas).to receive(:enabled?).and_return(true)
        allow(Gitlab::Kas).to receive(:internal_url).and_return(nil)
      end

      it 'raises a configuration error' do
        expect { described_class.new }.to raise_error(described_class::ConfigurationError, 'KAS internal URL is not configured')
      end
    end
  end

  describe 'gRPC calls' do
    let(:token) { instance_double(JSONWebToken::HMACToken, encoded: 'test-token') }
    let(:kas_url) { 'grpc://example.kas.internal' }

    before do
      allow(Gitlab::Kas).to receive(:enabled?).and_return(true)
      allow(Gitlab::Kas).to receive(:internal_url).and_return(kas_url)

      allow(JSONWebToken::HMACToken).to receive(:new)
        .with(Gitlab::Kas.secret)
        .and_return(token)

      allow(token).to receive(:issuer=).with(Settings.gitlab.host)
      allow(token).to receive(:audience=).with(described_class::JWT_AUDIENCE)
    end

    describe '#get_connected_agents_by_agent_ids' do
      let(:stub) { instance_double(Gitlab::Agent::AgentTracker::Rpc::AgentTracker::Stub) }
      let(:request) { instance_double(Gitlab::Agent::AgentTracker::Rpc::GetConnectedAgentsByAgentIDsRequest) }
      let(:response) { double(Gitlab::Agent::AgentTracker::Rpc::GetConnectedAgentsByAgentIDsResponse, agents: connected_agents) }

      let(:connected_agents) { [double] }

      subject { described_class.new.get_connected_agents_by_agent_ids(agent_ids: [agent.id]) }

      before do
        expect(Gitlab::Agent::AgentTracker::Rpc::AgentTracker::Stub).to receive(:new)
          .with('example.kas.internal', :this_channel_is_insecure, timeout: described_class::TIMEOUT)
          .and_return(stub)

        expect(Gitlab::Agent::AgentTracker::Rpc::GetConnectedAgentsByAgentIDsRequest).to receive(:new)
          .with(agent_ids: [agent.id])
          .and_return(request)

        expect(stub).to receive(:get_connected_agents_by_agent_i_ds)
          .with(request, metadata: { 'authorization' => 'bearer test-token' })
          .and_return(response)
      end

      it { expect(subject).to eq(connected_agents) }
    end

    describe '#list_agent_config_files' do
      let(:stub) { instance_double(Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub) }

      let(:request) { instance_double(Gitlab::Agent::ConfigurationProject::Rpc::ListAgentConfigFilesRequest) }
      let(:response) { double(Gitlab::Agent::ConfigurationProject::Rpc::ListAgentConfigFilesResponse, config_files: agent_configurations) }

      let(:repository) { instance_double(Gitlab::Agent::Entity::GitalyRepository) }
      let(:gitaly_info) { instance_double(Gitlab::Agent::Entity::GitalyInfo) }
      let(:gitaly_features) { Feature::Gitaly.server_feature_flags }

      let(:agent_configurations) { [double] }

      subject { described_class.new.list_agent_config_files(project: project) }

      before do
        expect(Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub).to receive(:new)
          .with('example.kas.internal', :this_channel_is_insecure, timeout: described_class::TIMEOUT)
          .and_return(stub)

        expect(Gitlab::Agent::Entity::GitalyRepository).to receive(:new)
          .with(project.repository.gitaly_repository.to_h)
          .and_return(repository)

        expect(Gitlab::Agent::Entity::GitalyInfo).to receive(:new)
          .with(Gitlab::GitalyClient.connection_data(project.repository_storage).merge(features: gitaly_features))
          .and_return(gitaly_info)

        expect(Gitlab::Agent::ConfigurationProject::Rpc::ListAgentConfigFilesRequest).to receive(:new)
          .with(repository: repository, gitaly_info: gitaly_info)
          .and_return(request)

        expect(stub).to receive(:list_agent_config_files)
          .with(request, metadata: { 'authorization' => 'bearer test-token' })
          .and_return(response)
      end

      it { expect(subject).to eq(agent_configurations) }
    end

    describe '#send_autoflow_event' do
      subject { described_class.new.send_autoflow_event(project: project, type: 'any-type', id: 'any-id', data: { 'any-data-key': 'any-data-value' }) }

      context 'when autoflow_enabled FF is disabled' do
        before do
          stub_feature_flags(autoflow_enabled: false)
        end

        it { expect(subject).to be_nil }
      end

      context 'when autoflow_enabled FF is enabled' do
        let(:stub) { instance_double(Gitlab::Agent::AutoFlow::Rpc::AutoFlow::Stub) }
        let(:request) { instance_double(Gitlab::Agent::AutoFlow::Rpc::CloudEventRequest) }
        let(:event_param) { instance_double(Gitlab::Agent::Event::CloudEvent) }
        let(:project_param) { instance_double(Gitlab::Agent::Event::Project) }
        let(:response) { double(Gitlab::Agent::AutoFlow::Rpc::CloudEventResponse) }

        before do
          stub_feature_flags(autoflow_enabled: true)

          expect(Gitlab::Agent::AutoFlow::Rpc::AutoFlow::Stub).to receive(:new)
            .with('example.kas.internal', :this_channel_is_insecure, timeout: described_class::TIMEOUT)
            .and_return(stub)

          expect(Gitlab::Agent::Event::Project).to receive(:new)
            .with(id: project.id, full_path: project.full_path)
            .and_return(project_param)

          expect(Gitlab::Agent::Event::CloudEvent).to receive(:new)
            .with(id: 'any-id', source: "GitLab", spec_version: "v1", type: 'any-type',
              attributes: {
                datacontenttype: Gitlab::Agent::Event::CloudEvent::CloudEventAttributeValue.new(
                  ce_string: "application/json"
                )
              },
              text_data: '{"any-data-key":"any-data-value"}'
            )
            .and_return(event_param)

          expect(Gitlab::Agent::AutoFlow::Rpc::CloudEventRequest).to receive(:new)
            .with(event: event_param, flow_project: project_param)
            .and_return(request)

          expect(stub).to receive(:cloud_event)
            .with(request, metadata: { 'authorization' => 'bearer test-token' })
            .and_return(response)
        end

        it { expect(subject).to eq(response) }
      end
    end

    describe '#send_git_push_event' do
      let(:stub) { instance_double(Gitlab::Agent::Notifications::Rpc::Notifications::Stub) }
      let(:request) { instance_double(Gitlab::Agent::Notifications::Rpc::GitPushEventRequest) }
      let(:event_param) { instance_double(Gitlab::Agent::Event::GitPushEvent) }
      let(:project_param) { instance_double(Gitlab::Agent::Event::Project) }
      let(:response) { double(Gitlab::Agent::Notifications::Rpc::GitPushEventResponse) }

      subject { described_class.new.send_git_push_event(project: project) }

      before do
        expect(Gitlab::Agent::Notifications::Rpc::Notifications::Stub).to receive(:new)
          .with('example.kas.internal', :this_channel_is_insecure, timeout: described_class::TIMEOUT)
          .and_return(stub)

        expect(Gitlab::Agent::Event::Project).to receive(:new)
          .with(id: project.id, full_path: project.full_path)
          .and_return(project_param)

        expect(Gitlab::Agent::Event::GitPushEvent).to receive(:new)
          .with(project: project_param)
          .and_return(event_param)

        expect(Gitlab::Agent::Notifications::Rpc::GitPushEventRequest).to receive(:new)
          .with(event: event_param)
          .and_return(request)

        expect(stub).to receive(:git_push_event)
          .with(request, metadata: { 'authorization' => 'bearer test-token' })
          .and_return(response)
      end

      it { expect(subject).to eq(response) }
    end

    describe 'with grpcs' do
      let(:stub) { instance_double(Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub) }
      let(:credentials) { instance_double(GRPC::Core::ChannelCredentials) }
      let(:kas_url) { 'grpcs://example.kas.internal' }

      it 'uses a ChannelCredentials object with the correct certificates' do
        expect(GRPC::Core::ChannelCredentials).to receive(:new)
          .with(Gitlab::X509::Certificate.ca_certs_bundle)
          .and_return(credentials)

        expect(Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub).to receive(:new)
          .with('example.kas.internal', credentials, timeout: described_class::TIMEOUT)
          .and_return(stub)

        allow(stub).to receive(:list_agent_config_files)
          .and_return(double(config_files: []))

        described_class.new.list_agent_config_files(project: project)
      end
    end
  end
end
