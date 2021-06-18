# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillJiraTrackerDeploymentType2, :migration, schema: 20201028182809 do
  let_it_be(:jira_integration_temp) { described_class::JiraServiceTemp }
  let_it_be(:jira_tracker_data_temp) { described_class::JiraTrackerDataTemp }
  let_it_be(:atlassian_host) { 'https://api.atlassian.net' }
  let_it_be(:mixedcase_host) { 'https://api.AtlassiaN.nEt' }
  let_it_be(:server_host) { 'https://my.server.net' }

  let(:jira_integration) { jira_integration_temp.create!(type: 'JiraService', active: true, category: 'issue_tracker') }

  subject { described_class.new }

  def create_tracker_data(options = {})
    jira_tracker_data_temp.create!({ service_id: jira_integration.id }.merge(options))
  end

  describe '#perform' do
    context do
      it 'ignores if deployment already set' do
        tracker_data = create_tracker_data(url: atlassian_host, deployment_type: 'server')

        expect(subject).not_to receive(:collect_deployment_type)

        subject.perform(tracker_data.id, tracker_data.id)

        expect(tracker_data.reload.deployment_type).to eq 'server'
      end

      it 'ignores if no url is set' do
        tracker_data = create_tracker_data(deployment_type: 'unknown')

        expect(subject).to receive(:collect_deployment_type)

        subject.perform(tracker_data.id, tracker_data.id)

        expect(tracker_data.reload.deployment_type).to eq 'unknown'
      end
    end

    context 'when tracker is valid' do
      let!(:tracker_1) { create_tracker_data(url: atlassian_host, deployment_type: 0) }
      let!(:tracker_2) { create_tracker_data(url: mixedcase_host, deployment_type: 0) }
      let!(:tracker_3) { create_tracker_data(url: server_host, deployment_type: 0) }
      let!(:tracker_4) { create_tracker_data(api_url: server_host, deployment_type: 0) }
      let!(:tracker_nextbatch) { create_tracker_data(api_url: atlassian_host, deployment_type: 0) }

      it 'sets the proper deployment_type', :aggregate_failures do
        subject.perform(tracker_1.id, tracker_4.id)

        expect(tracker_1.reload.deployment_cloud?).to be_truthy
        expect(tracker_2.reload.deployment_cloud?).to be_truthy
        expect(tracker_3.reload.deployment_server?).to be_truthy
        expect(tracker_4.reload.deployment_server?).to be_truthy
        expect(tracker_nextbatch.reload.deployment_unknown?).to be_truthy
      end
    end

    it_behaves_like 'marks background migration job records' do
      let(:arguments) { [1, 4] }
    end
  end
end
