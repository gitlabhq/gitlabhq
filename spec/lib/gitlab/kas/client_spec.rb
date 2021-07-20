# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kas::Client do
  let_it_be(:project) { create(:project) }

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

      expect(JSONWebToken::HMACToken).to receive(:new)
        .with(Gitlab::Kas.secret)
        .and_return(token)

      expect(token).to receive(:issuer=).with(Settings.gitlab.host)
      expect(token).to receive(:audience=).with(described_class::JWT_AUDIENCE)
    end

    describe '#list_agent_config_files' do
      let(:stub) { instance_double(Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub) }

      let(:request) { instance_double(Gitlab::Agent::ConfigurationProject::Rpc::ListAgentConfigFilesRequest) }
      let(:response) { double(Gitlab::Agent::ConfigurationProject::Rpc::ListAgentConfigFilesResponse, config_files: agent_configurations) }

      let(:repository) { instance_double(Gitlab::Agent::Modserver::Repository) }
      let(:gitaly_address) { instance_double(Gitlab::Agent::Modserver::GitalyAddress) }

      let(:agent_configurations) { [double] }

      subject { described_class.new.list_agent_config_files(project: project) }

      before do
        expect(Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub).to receive(:new)
          .with('example.kas.internal', :this_channel_is_insecure, timeout: described_class::TIMEOUT)
          .and_return(stub)

        expect(Gitlab::Agent::Modserver::Repository).to receive(:new)
          .with(project.repository.gitaly_repository.to_h)
          .and_return(repository)

        expect(Gitlab::Agent::Modserver::GitalyAddress).to receive(:new)
          .with(Gitlab::GitalyClient.connection_data(project.repository_storage))
          .and_return(gitaly_address)

        expect(Gitlab::Agent::ConfigurationProject::Rpc::ListAgentConfigFilesRequest).to receive(:new)
          .with(repository: repository, gitaly_address: gitaly_address)
          .and_return(request)

        expect(stub).to receive(:list_agent_config_files)
          .with(request, metadata: { 'authorization' => 'bearer test-token' })
          .and_return(response)
      end

      it { expect(subject).to eq(agent_configurations) }
    end

    describe 'with grpcs' do
      let(:stub) { instance_double(Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub) }
      let(:kas_url) { 'grpcs://example.kas.internal' }

      it 'uses a ChannelCredentials object' do
        expect(Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub).to receive(:new)
          .with('example.kas.internal', instance_of(GRPC::Core::ChannelCredentials), timeout: described_class::TIMEOUT)
          .and_return(stub)

        allow(stub).to receive(:list_agent_config_files)
          .and_return(double(config_files: []))

        described_class.new.list_agent_config_files(project: project)
      end
    end
  end
end
