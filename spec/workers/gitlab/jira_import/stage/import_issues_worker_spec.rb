# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::Stage::ImportIssuesWorker, :clean_gitlab_redis_cache, feature_category: :importers do
  include JiraIntegrationHelpers

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

    context 'when import started' do
      let(:job_waiter) { Gitlab::JobWaiter.new(2, 'some-job-key') }

      before_all do
        create(:jira_integration, project: project)
      end

      before do
        jira_import.start!
        allow_next_instance_of(Gitlab::JiraImport::IssuesImporter) do |instance|
          allow(instance).to receive(:execute).and_return(job_waiter)
        end
      end

      it 'creates issues importer' do
        issue_importer = instance_double(Gitlab::JiraImport::IssuesImporter)

        allow(Project).to receive(:find_by_id).with(project.id).and_return(project)
        allow(issue_importer).to receive(:execute).and_return(job_waiter)

        expect(Gitlab::JiraImport::IssuesImporter).to receive(:new).with(project).and_return(issue_importer)

        described_class.new.perform(project.id)
      end

      context 'when pagination state indicates not last page' do
        before do
          allow(Gitlab::JiraImport).to receive(:get_pagination_state).with(project.id)
            .and_return({ is_last: false, next_page_token: 'token123', page: 1 })
        end

        it_behaves_like 'advance to next stage', :issues
      end

      context 'when pagination state indicates last page' do
        before do
          allow(Gitlab::JiraImport).to receive(:get_pagination_state).with(project.id)
            .and_return({ is_last: true, next_page_token: nil, page: 2 })
        end

        it_behaves_like 'advance to next stage', :attachments
      end

      context 'when pagination state is not set' do
        before do
          allow(Gitlab::JiraImport).to receive(:get_pagination_state).with(project.id)
            .and_return({ is_last: false, next_page_token: nil, page: 1 })
        end

        it_behaves_like 'advance to next stage', :issues
      end
    end
  end
end
