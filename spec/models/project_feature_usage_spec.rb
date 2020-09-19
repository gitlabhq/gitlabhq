# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectFeatureUsage, type: :model do
  describe '.jira_dvcs_integrations_enabled_count' do
    it 'returns count of projects with Jira DVCS Cloud enabled' do
      create(:project).feature_usage.log_jira_dvcs_integration_usage
      create(:project).feature_usage.log_jira_dvcs_integration_usage

      expect(described_class.with_jira_dvcs_integration_enabled.count).to eq(2)
    end

    it 'returns count of projects with Jira DVCS Server enabled' do
      create(:project).feature_usage.log_jira_dvcs_integration_usage(cloud: false)
      create(:project).feature_usage.log_jira_dvcs_integration_usage(cloud: false)

      expect(described_class.with_jira_dvcs_integration_enabled(cloud: false).count).to eq(2)
    end
  end

  describe '#log_jira_dvcs_integration_usage' do
    let(:project) { create(:project) }

    subject { project.feature_usage }

    it 'logs Jira DVCS Cloud last sync' do
      Timecop.freeze do
        subject.log_jira_dvcs_integration_usage

        expect(subject.jira_dvcs_server_last_sync_at).to be_nil
        expect(subject.jira_dvcs_cloud_last_sync_at).to be_like_time(Time.current)
      end
    end

    it 'logs Jira DVCS Server last sync' do
      Timecop.freeze do
        subject.log_jira_dvcs_integration_usage(cloud: false)

        expect(subject.jira_dvcs_server_last_sync_at).to be_like_time(Time.current)
        expect(subject.jira_dvcs_cloud_last_sync_at).to be_nil
      end
    end

    context 'when log_jira_dvcs_integration_usage is called simultaneously for the same project' do
      it 'logs the latest call' do
        feature_usage = project.feature_usage
        feature_usage.log_jira_dvcs_integration_usage
        first_logged_at = feature_usage.jira_dvcs_cloud_last_sync_at

        Timecop.freeze(1.hour.from_now) do
          ProjectFeatureUsage.new(project_id: project.id).log_jira_dvcs_integration_usage
        end

        expect(feature_usage.reload.jira_dvcs_cloud_last_sync_at).to be > first_logged_at
      end
    end
  end
end
