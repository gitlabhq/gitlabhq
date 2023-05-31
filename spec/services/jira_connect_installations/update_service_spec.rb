# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectInstallations::UpdateService, feature_category: :integrations do
  describe '.execute' do
    it 'creates an instance and calls execute' do
      expect_next_instance_of(described_class, 'param1', 'param2') do |update_service|
        expect(update_service).to receive(:execute)
      end

      described_class.execute('param1', 'param2')
    end
  end

  describe '#execute' do
    let_it_be_with_reload(:installation) { create(:jira_connect_installation) }
    let(:update_params) { { client_key: 'new_client_key' } }

    subject(:execute_service) { described_class.new(installation, update_params).execute }

    it 'returns a ServiceResponse' do
      expect(execute_service).to be_kind_of(ServiceResponse)
      expect(execute_service[:status]).to eq(:success)
    end

    it 'updates the installation' do
      expect { execute_service }.to change { installation.client_key }.to('new_client_key')
    end

    it 'returns a successful result' do
      expect(execute_service.success?).to eq(true)
    end

    context 'and model validation fails' do
      let(:update_params) { { instance_url: 'invalid' } }

      it 'returns an error result' do
        expect(execute_service.error?).to eq(true)
        expect(execute_service.message).to eq(installation.errors)
      end
    end

    context 'and the installation has an instance_url' do
      let_it_be_with_reload(:installation) { create(:jira_connect_installation, instance_url: 'https://other_gitlab.example.com') }

      it 'sends an installed event to the instance', :aggregate_failures do
        expect_next_instance_of(
          JiraConnectInstallations::ProxyLifecycleEventService, installation, :installed, 'https://other_gitlab.example.com'
        ) do |proxy_lifecycle_events_service|
          expect(proxy_lifecycle_events_service).to receive(:execute).and_return(ServiceResponse.new(status: :success))
        end

        expect(JiraConnect::SendUninstalledHookWorker).not_to receive(:perform_async)

        expect { execute_service }.not_to change { installation.instance_url }
      end

      context 'and instance_url gets updated' do
        let(:update_params) { { instance_url: 'https://gitlab.example.com' } }

        before do
          stub_request(:post, 'https://other_gitlab.example.com/-/jira_connect/events/uninstalled')
        end

        it 'sends an installed event to the instance and updates instance_url' do
          expect(JiraConnectInstallations::ProxyLifecycleEventService)
            .to receive(:execute).with(installation, :installed, 'https://gitlab.example.com')
            .and_return(ServiceResponse.new(status: :success))

          expect(JiraConnect::SendUninstalledHookWorker).not_to receive(:perform_async)

          execute_service

          expect(installation.instance_url).to eq(update_params[:instance_url])
        end

        context 'and the new instance_url is nil' do
          let(:update_params) { { instance_url: nil } }

          it 'starts an async worker to send an uninstalled event to the previous instance' do
            expect(JiraConnect::SendUninstalledHookWorker).to receive(:perform_async).with(installation.id, 'https://other_gitlab.example.com')

            execute_service

            expect(installation.instance_url).to eq(nil)
          end

          it 'does not send an installed event' do
            expect(JiraConnectInstallations::ProxyLifecycleEventService).not_to receive(:new)

            execute_service
          end
        end
      end
    end

    context 'and instance_url is updated' do
      let(:update_params) { { instance_url: 'https://gitlab.example.com' } }

      it 'sends an installed event to the instance and updates instance_url' do
        expect_next_instance_of(
          JiraConnectInstallations::ProxyLifecycleEventService, installation, :installed, 'https://gitlab.example.com'
        ) do |proxy_lifecycle_events_service|
          expect(proxy_lifecycle_events_service).to receive(:execute).and_return(ServiceResponse.new(status: :success))
        end

        expect(JiraConnect::SendUninstalledHookWorker).not_to receive(:perform_async)

        execute_service

        expect(installation.instance_url).to eq(update_params[:instance_url])
      end

      context 'and the instance installation cannot be created' do
        before do
          allow_next_instance_of(
            JiraConnectInstallations::ProxyLifecycleEventService,
            installation,
            :installed,
            'https://gitlab.example.com'
          ) do |proxy_lifecycle_events_service|
            allow(proxy_lifecycle_events_service).to receive(:execute).and_return(
              ServiceResponse.error(
                message: {
                  type: :response_error,
                  code: '422'
                }
              )
            )
          end
        end

        it 'does not change instance_url' do
          expect { execute_service }.not_to change { installation.instance_url }
        end

        it 'returns an error message' do
          expect(execute_service[:status]).to eq(:error)
          expect(execute_service[:message]).to eq("Could not be installed on the instance. Error response code 422")
        end

        context 'and the installation had a previous instance_url' do
          let(:installation) { build(:jira_connect_installation, instance_url: 'https://other_gitlab.example.com') }

          it 'does not send the uninstalled hook to the previous instance_url' do
            expect(JiraConnect::SendUninstalledHookWorker).not_to receive(:perform_async)

            execute_service
          end
        end

        context 'when failure because of a network error' do
          before do
            allow_next_instance_of(
              JiraConnectInstallations::ProxyLifecycleEventService,
              installation,
              :installed,
              'https://gitlab.example.com'
            ) do |proxy_lifecycle_events_service|
              allow(proxy_lifecycle_events_service).to receive(:execute).and_return(
                ServiceResponse.error(
                  message: {
                    type: :network_error,
                    message: 'Connection refused - error message'
                  }
                )
              )
            end
          end

          it 'returns an error message' do
            expect(execute_service[:status]).to eq(:error)
            expect(execute_service[:message]).to eq("Could not be installed on the instance. Network error")
          end
        end
      end
    end
  end
end
