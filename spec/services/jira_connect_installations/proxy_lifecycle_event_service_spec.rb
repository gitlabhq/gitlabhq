# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectInstallations::ProxyLifecycleEventService, feature_category: :integrations do
  describe '.execute' do
    let(:installation) { create(:jira_connect_installation) }

    it 'creates an instance and calls execute' do
      expect_next_instance_of(described_class, installation, 'installed', 'https://test.gitlab.com') do |update_service|
        expect(update_service).to receive(:execute)
      end

      described_class.execute(installation, 'installed', 'https://test.gitlab.com')
    end
  end

  describe '.new' do
    let_it_be(:installation) { create(:jira_connect_installation, instance_url: nil) }

    let(:event) { :installed }

    subject(:service) { described_class.new(installation, event, 'https://test.gitlab.com') }

    it 'creates an internal duplicate of the installation and sets the instance_url' do
      expect(service.instance_variable_get(:@installation).instance_url).to eq('https://test.gitlab.com')
    end

    context 'with unknown event' do
      let(:event) { 'test' }

      it 'raises an error' do
        expect { service }.to raise_error(ArgumentError, 'Unknown event \'test\'')
      end
    end
  end

  describe '#execute' do
    let_it_be(:installation) { create(:jira_connect_installation, instance_url: 'https://old_instance_url.example.com') }

    let(:service) { described_class.new(installation, evnet_type, 'https://gitlab.example.com') }
    let(:service_instance_installation) { service.instance_variable_get(:@installation) }

    before do
      allow_next_instance_of(JiraConnect::CreateAsymmetricJwtService) do |create_asymmetric_jwt_service|
        allow(create_asymmetric_jwt_service).to receive(:execute).and_return('123456')
      end

      stub_request(:post, hook_url)
    end

    subject(:execute_service) { service.execute }

    shared_examples 'sends the event hook' do
      it 'returns a ServiceResponse' do
        expect(execute_service).to be_kind_of(ServiceResponse)
        expect(execute_service[:status]).to eq(:success)
      end

      it 'sends an installed event to the instance' do
        execute_service

        expect(WebMock).to have_requested(:post, hook_url).with(body: expected_request_body)
      end

      it 'creates the JWT token with the event and installation' do
        expect_next_instance_of(
          JiraConnect::CreateAsymmetricJwtService,
          service_instance_installation,
          event: evnet_type
        ) do |create_asymmetric_jwt_service|
          expect(create_asymmetric_jwt_service).to receive(:execute).and_return('123456')
        end

        expect(execute_service[:status]).to eq(:success)
      end

      context 'and the instance responds with an error' do
        before do
          stub_request(:post, hook_url).to_return(
            status: 422,
            body: 'Error message',
            headers: {}
          )
        end

        it 'returns an error ServiceResponse', :aggregate_failures do
          expect(execute_service).to be_kind_of(ServiceResponse)
          expect(execute_service[:status]).to eq(:error)
          expect(execute_service[:message]).to eq({ type: :response_error, code: 422 })
        end

        it 'logs the error response' do
          expect(Gitlab::IntegrationsLogger).to receive(:info).with(
            integration: 'JiraConnect',
            message: 'Proxy lifecycle event received error response',
            jira_event_type: evnet_type,
            jira_status_code: 422,
            jira_body: 'Error message'
          )

          execute_service
        end
      end

      context 'and the request raises an error' do
        before do
          allow(Gitlab::HTTP).to receive(:post).and_raise(Errno::ECONNREFUSED, 'error message')
        end

        it 'returns an error ServiceResponse', :aggregate_failures do
          expect(execute_service).to be_kind_of(ServiceResponse)
          expect(execute_service[:status]).to eq(:error)
          expect(execute_service[:message]).to eq(
            {
              type: :network_error,
              message: 'Connection refused - error message'
            }
          )
        end
      end
    end

    context 'when installed event' do
      let(:evnet_type) { :installed }
      let(:hook_url) { 'https://gitlab.example.com/-/jira_connect/events/installed' }
      let(:expected_request_body) do
        {
          clientKey: installation.client_key,
          sharedSecret: installation.shared_secret,
          baseUrl: installation.base_url,
          jwt: '123456',
          eventType: 'installed'
        }
      end

      it_behaves_like 'sends the event hook'
    end

    context 'when uninstalled event' do
      let(:evnet_type) { :uninstalled }
      let(:hook_url) { 'https://gitlab.example.com/-/jira_connect/events/uninstalled' }
      let(:expected_request_body) do
        {
          clientKey: installation.client_key,
          jwt: '123456',
          eventType: 'uninstalled'
        }
      end

      it_behaves_like 'sends the event hook'
    end
  end
end
