# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport::Stage::ImportIssuesWorker do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe 'modules' do
    it_behaves_like 'include import workers modules'
  end

  describe '#perform' do
    context 'when feature flag enabled' do
      before do
        stub_feature_flags(jira_issue_import: false)
      end

      it_behaves_like 'exit import not started'
    end

    context 'when feature flag enabled' do
      before do
        stub_feature_flags(jira_issue_import: true)
      end

      context 'when import did not start' do
        let!(:import_state) { create(:import_state, project: project) }

        it_behaves_like 'exit import not started'
      end

      context 'when import started', :clean_gitlab_redis_cache do
        let(:jira_import_data) do
          data = JiraImportData.new
          data << JiraImportData::JiraProjectDetails.new('XX', Time.now.strftime('%Y-%m-%d %H:%M:%S'), { user_id: user.id, name: user.name })
          data
        end
        let(:project) { create(:project, import_data: jira_import_data) }
        let!(:jira_service) { create(:jira_service, project: project) }
        let!(:import_state) { create(:import_state, status: :started, project: project) }

        before do
          allow_next_instance_of(Gitlab::JiraImport::IssuesImporter) do |instance|
            allow(instance).to receive(:fetch_issues).and_return([])
          end
        end

        context 'when start_at is nil' do
          it_behaves_like 'advance to next stage', :attachments
        end

        context 'when start_at is zero' do
          before do
            allow(Gitlab::Cache::Import::Caching).to receive(:read).and_return(0)
          end

          it_behaves_like 'advance to next stage', :issues
        end

        context 'when start_at is greater than zero' do
          before do
            allow(Gitlab::Cache::Import::Caching).to receive(:read).and_return(25)
          end

          it_behaves_like 'advance to next stage', :issues
        end

        context 'when start_at is below zero' do
          before do
            allow(Gitlab::Cache::Import::Caching).to receive(:read).and_return(-1)
          end

          it_behaves_like 'advance to next stage', :attachments
        end
      end
    end
  end
end
