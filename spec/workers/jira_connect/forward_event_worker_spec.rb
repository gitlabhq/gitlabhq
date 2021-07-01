# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::ForwardEventWorker do
  describe '#perform' do
    let!(:jira_connect_installation) { create(:jira_connect_installation, instance_url: self_managed_url, client_key: client_key, shared_secret: shared_secret) }
    let(:base_path) { '/-/jira_connect' }
    let(:event_path) { '/-/jira_connect/events/uninstalled' }

    let(:self_managed_url) { 'http://example.com' }
    let(:base_url) { self_managed_url + base_path }
    let(:event_url) { self_managed_url + event_path }

    let(:client_key) { '123' }
    let(:shared_secret) { '123' }

    subject { described_class.new.perform(jira_connect_installation.id, base_path, event_path) }

    it 'forwards the event including the auth header and deletes the installation' do
      stub_request(:post, event_url)

      expect(Atlassian::Jwt).to receive(:create_query_string_hash).with(event_url, 'POST', base_url).and_return('some_qsh')
      expect(Atlassian::Jwt).to receive(:encode).with({ iss: client_key, qsh: 'some_qsh' }, shared_secret).and_return('auth_token')
      expect { subject }.to change(JiraConnectInstallation, :count).by(-1)

      expect(WebMock).to have_requested(:post, event_url).with(headers: { 'Authorization' => 'JWT auth_token' })
    end

    context 'when installation does not exist' do
      let(:jira_connect_installation) { instance_double(JiraConnectInstallation, id: -1) }

      it 'does nothing' do
        expect { subject }.not_to change(JiraConnectInstallation, :count)
      end
    end

    context 'when installation does not have an instance_url' do
      let!(:jira_connect_installation) { create(:jira_connect_installation) }

      it 'forwards the event including the auth header' do
        expect { subject }.to change(JiraConnectInstallation, :count).by(-1)

        expect(WebMock).not_to have_requested(:post, '*')
      end
    end

    context 'when it fails to forward the event' do
      it 'still deletes the installation' do
        allow(Gitlab::HTTP).to receive(:post).and_raise(StandardError)

        expect { subject }.to raise_error(StandardError).and change(JiraConnectInstallation, :count).by(-1)
      end
    end
  end
end
