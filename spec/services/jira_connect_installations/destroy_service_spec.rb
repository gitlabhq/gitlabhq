# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectInstallations::DestroyService, feature_category: :integrations do
  describe '.execute' do
    it 'creates an instance and calls execute' do
      expect_next_instance_of(described_class, 'param1', 'param2', 'param3') do |destroy_service|
        expect(destroy_service).to receive(:execute)
      end

      described_class.execute('param1', 'param2', 'param3')
    end
  end

  describe '#execute' do
    let_it_be(:group1) { create(:group) }
    let_it_be(:group2) { create(:group) }

    let!(:installation) { create(:jira_connect_installation) }

    let(:jira_base_path) { '/-/jira_connect' }
    let(:jira_event_path) { '/-/jira_connect/events/uninstalled' }

    before do
      create(:jira_connect_subscription, installation: installation, namespace: group1)
      create(:jira_connect_subscription, installation: installation, namespace: group2)
    end

    subject { described_class.new(installation, jira_base_path, jira_event_path).execute }

    it { is_expected.to be_truthy }

    it 'schedules a JiraCloudAppDeactivationWorker background job and deletes the installation' do
      expect(JiraConnect::JiraCloudAppDeactivationWorker).to receive(:perform_async).with(group1.id)
      expect(JiraConnect::JiraCloudAppDeactivationWorker).to receive(:perform_async).with(group2.id)

      expect { subject }.to change(JiraConnectInstallation, :count).by(-1)
    end

    context 'and the installation has an instance_url set' do
      let!(:installation) { create(:jira_connect_installation, instance_url: 'http://example.com') }

      it { is_expected.to be_truthy }

      it 'schedules a ForwardEventWorker background job and keeps the installation' do
        expect(JiraConnect::ForwardEventWorker).to receive(:perform_async).with(installation.id, jira_base_path, jira_event_path)

        expect { subject }.not_to change(JiraConnectInstallation, :count)
      end
    end
  end
end
