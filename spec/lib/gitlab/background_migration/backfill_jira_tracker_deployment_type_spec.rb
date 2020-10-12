# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillJiraTrackerDeploymentType, :migration, schema: 20200910155617 do
  let_it_be(:jira_service_temp) { described_class::JiraServiceTemp }
  let_it_be(:jira_tracker_data_temp) { described_class::JiraTrackerDataTemp }
  let_it_be(:api_host) { 'https://api.atlassian.net' }
  let(:jira_service) { jira_service_temp.create!(type: 'JiraService', active: true, category: 'issue_tracker') }

  subject { described_class.new }

  describe '#perform' do
    context 'when tracker is not valid' do
      it 'returns if deployment already set' do
        jira_tracker_data = jira_tracker_data_temp.create!(service_id: jira_service.id,
                                                           url: api_host, deployment_type: 1)

        expect(subject).not_to receive(:update_deployment_type)

        subject.perform(jira_tracker_data.id)
      end

      it 'returns if no url is set' do
        jira_tracker_data = jira_tracker_data_temp.create!(service_id: jira_service.id,
                                                           deployment_type: 0)

        expect(subject).not_to receive(:update_deployment_type)

        subject.perform(jira_tracker_data.id)
      end
    end

    context 'when tracker is valid' do
      let(:jira_tracker_data) do
        jira_tracker_data_temp.create!(service_id: jira_service.id,
                                       url: api_host, deployment_type: 0)
      end

      it 'sets the deployment_type to cloud' do
        subject.perform(jira_tracker_data.id)

        expect(jira_tracker_data.reload.deployment_cloud?).to be_truthy
      end

      describe 'with a mixed case url' do
        let_it_be(:api_host) { 'https://api.AtlassiaN.nEt' }

        it 'sets the deployment_type to cloud' do
          subject.perform(jira_tracker_data.id)

          expect(jira_tracker_data.reload.deployment_cloud?).to be_truthy
        end
      end

      describe 'with a Jira Server' do
        let_it_be(:api_host) { 'https://my.server.net' }

        it 'sets the deployment_type to server' do
          subject.perform(jira_tracker_data.id)

          expect(jira_tracker_data.reload.deployment_server?).to be_truthy
        end
      end

      describe 'with api_url specified' do
        let(:jira_tracker_data) do
          jira_tracker_data_temp.create!(service_id: jira_service.id,
                                         api_url: api_host, deployment_type: 0)
        end

        it 'sets the deployment_type to cloud' do
          subject.perform(jira_tracker_data.id)

          expect(jira_tracker_data.reload.deployment_cloud?).to be_truthy
        end
      end
    end
  end
end
