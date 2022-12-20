# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::SendUninstalledHookWorker, feature_category: :integrations do
  describe '#perform' do
    let_it_be(:jira_connect_installation) { create(:jira_connect_installation) }
    let(:instance_url) { 'http://example.com' }
    let(:attempts) { 3 }
    let(:service_response) { ServiceResponse.new(status: :success) }
    let(:job_args) { [jira_connect_installation.id, instance_url] }

    before do
      allow(JiraConnectInstallations::ProxyLifecycleEventService).to receive(:execute).and_return(service_response)
    end

    include_examples 'an idempotent worker' do
      it 'calls the ProxyLifecycleEventService service' do
        expect(JiraConnectInstallations::ProxyLifecycleEventService).to receive(:execute).with(
          jira_connect_installation,
          :uninstalled,
          instance_url
        ).twice

        subject
      end
    end
  end
end
