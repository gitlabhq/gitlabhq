# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::Stage::ImportIssuesWorker do
  include JiraServiceHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, import_type: 'jira') }

  describe 'modules' do
    it_behaves_like 'include import workers modules'
  end

  describe '#perform' do
    let_it_be(:jira_import, reload: true) { create(:jira_import_state, :scheduled, project: project) }

    before do
      stub_jira_integration_test
    end

    context 'when import did not start' do
      it_behaves_like 'cannot do Jira import'
      it_behaves_like 'does not advance to next stage'
    end

    context 'when import started', :clean_gitlab_redis_cache do
      let_it_be(:jira_integration) { create(:jira_integration, project: project) }

      before do
        jira_import.start!
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
