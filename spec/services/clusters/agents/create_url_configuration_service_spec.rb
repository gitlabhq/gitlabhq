# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::CreateUrlConfigurationService, feature_category: :deployment_management do
  describe '#execute' do
    let_it_be_with_reload(:agent) { create(:cluster_agent) }
    let_it_be_with_reload(:project) { agent.project }
    let_it_be_with_reload(:user) { create(:user, maintainer_of: project) }

    let(:url) { 'grpc://agent.example.com' }
    let(:params) { { url: url } }

    subject(:service) { described_class.new(agent: agent, current_user: user, params: params) }

    context 'when receptive agents are enabled' do
      before do
        stub_application_setting(receptive_cluster_agents_enabled: true)
      end

      context 'when using public key auth' do
        let(:private_key) { Ed25519::SigningKey.generate }
        let(:public_key) { private_key.verify_key }

        before do
          allow(Ed25519::SigningKey).to receive(:generate).and_return(private_key)
        end

        it 'creates a new configuration' do
          response = service.execute

          expect(response).to be_success
          expect(agent.agent_url_configuration).to have_attributes(
            project: project,
            created_by_user: user,
            url: url,
            public_key: public_key.to_bytes,
            private_key: private_key.to_bytes.force_encoding('UTF-8')
          )
          expect(agent.is_receptive).to be(true)
        end
      end

      context 'when using certificate auth' do
        let(:client_cert) { File.read(Rails.root.join('spec/fixtures/clusters/sample_cert.pem')) }
        let(:client_key) { File.read(Rails.root.join('spec/fixtures/clusters/sample_key.key')) }
        let(:ca_cert) { File.read(Rails.root.join('spec/fixtures/clusters/sample_cert.pem')) }
        let(:tls_host) { 'host.example.com' }

        let(:params) do
          {
            url: url,
            client_cert: client_cert,
            client_key: client_key,
            ca_cert: ca_cert,
            tls_host: tls_host
          }
        end

        it 'creates a new configuration' do
          response = service.execute

          expect(response).to be_success
          expect(agent.agent_url_configuration).to have_attributes(
            project: project,
            created_by_user: user,
            url: url,
            client_cert: client_cert,
            client_key: client_key,
            ca_cert: ca_cert,
            tls_host: tls_host
          )
        end
      end

      context 'when the configuration has a validation error' do
        let(:url) { 'not.a.url' }

        it 'returns an error' do
          response = service.execute

          expect(response.status).to eq(:error)
          expect(response.message).to eq(['Url is not a valid URL'])
        end
      end

      context 'when the user does not have permission' do
        let(:user) { create(:user) }

        it 'returns an error' do
          response = service.execute

          expect(response.status).to eq(:error)
          expect(response.message).to eq(
            'You have insufficient permissions to create an url configuration for this agent'
          )
        end
      end

      context 'when the associated agent already has a url configuration' do
        let_it_be(:agent) { create(:cluster_agent, project: project, is_receptive: true) }

        it 'returns an error' do
          response = service.execute

          expect(response.status).to eq(:error)
          expect(response.message).to eq('URL configuration already exists for this agent')
        end
      end
    end

    context 'when receptive agents are disabled' do
      before do
        stub_application_setting(receptive_cluster_agents_enabled: false)
      end

      it 'returns an error' do
        response = service.execute

        expect(response.status).to eq(:error)
        expect(response.message).to eq('Receptive agents are disabled for this GitLab instance')
      end
    end
  end
end
