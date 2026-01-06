# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::IssuesImporter, :clean_gitlab_redis_shared_state do
  include JiraIntegrationHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:jira_import) { create(:jira_import_state, project: project, user: current_user) }
  let_it_be(:jira_integration) { create(:jira_integration, project: project) }
  let_it_be(:default_issue_type) { WorkItems::Type.default_issue_type }

  subject { described_class.new(project) }

  before do
    stub_jira_integration_test
  end

  describe '#imported_items_cache_key' do
    it_behaves_like 'raise exception if not implemented'
    it { expect(subject.imported_items_cache_key).to eq("jira-importer/already-imported/#{project.id}/issues") }
  end

  describe '#execute' do
    context 'when no returned issues' do
      it 'does not schedule any import jobs' do
        expect(subject).to receive(:fetch_issues).with(0).and_return([])
        expect(subject).not_to receive(:already_imported?)
        expect(subject).not_to receive(:mark_as_imported)
        expect(Gitlab::JiraImport::ImportIssueWorker).not_to receive(:perform_async)

        job_waiter = subject.execute

        expect(job_waiter.jobs_remaining).to eq(0)
        expect(Gitlab::JiraImport.get_issues_next_start_at(project.id)).to eq(-1)
      end
    end

    context 'with results returned' do
      jira_issue = Struct.new(:id)
      let_it_be(:jira_issues) { [jira_issue.new(1), jira_issue.new(2)] }

      def mock_issue_serializer(count, raise_exception_on_even_mocks: false)
        serializer = instance_double(Gitlab::JiraImport::IssueSerializer, execute: { key: 'data' })
        allow(Issue).to receive(:with_namespace_iid_supply).and_return('issue_iid')

        count.times do |i|
          if raise_exception_on_even_mocks && i.even?
            expect(Gitlab::JiraImport::IssueSerializer).to receive(:new).with(
              project,
              jira_issues[i],
              current_user.id,
              default_issue_type,
              { iid: 'issue_iid' }
            ).and_raise('Some error')
          else
            expect(Gitlab::JiraImport::IssueSerializer).to receive(:new).with(
              project,
              jira_issues[i],
              current_user.id,
              default_issue_type,
              { iid: 'issue_iid' }
            ).and_return(serializer)
          end
        end
      end

      context 'when single page of results is returned' do
        before do
          stub_const("#{described_class.name}::BATCH_SIZE", 3)
        end

        it 'schedules 2 import jobs' do
          expect(subject).to receive(:fetch_issues).with(0).and_return([jira_issues[0], jira_issues[1]])
          expect(Gitlab::JiraImport::ImportIssueWorker).to receive(:perform_async).twice
          expect(Gitlab::Cache::Import::Caching).to receive(:set_add).twice.and_call_original
          expect(Gitlab::Cache::Import::Caching).to receive(:set_includes?).twice.and_call_original
          mock_issue_serializer(2)

          job_waiter = subject.execute

          expect(job_waiter.jobs_remaining).to eq(2)
          expect(Gitlab::JiraImport.get_issues_next_start_at(project.id)).to eq(2)
        end
      end

      context 'when importing some issue raises an exception' do
        before do
          stub_const("#{described_class.name}::BATCH_SIZE", 3)
        end

        it 'schedules 2 import jobs' do
          expect(subject).to receive(:fetch_issues).with(0).and_return([jira_issues[0], jira_issues[1]])
          expect(Gitlab::JiraImport::ImportIssueWorker).to receive(:perform_async).once
          expect(Gitlab::Cache::Import::Caching).to receive(:set_add).once.and_call_original
          expect(Gitlab::Cache::Import::Caching).to receive(:set_includes?).twice.and_call_original
          expect(Gitlab::ErrorTracking).to receive(:track_exception).once
          mock_issue_serializer(2, raise_exception_on_even_mocks: true)

          job_waiter = subject.execute

          expect(job_waiter.jobs_remaining).to eq(1)
          expect(Gitlab::JiraImport.get_issues_next_start_at(project.id)).to eq(2)
        end
      end

      context 'when duplicate results are returned' do
        before do
          stub_const("#{described_class.name}::BATCH_SIZE", 2)
        end

        it 'schedules 2 import jobs' do
          expect(subject).to receive(:fetch_issues).with(0).and_return([jira_issues[0], jira_issues[0]])
          expect(Gitlab::JiraImport::ImportIssueWorker).to receive(:perform_async).once
          expect(Gitlab::Cache::Import::Caching).to receive(:set_add).once.and_call_original
          expect(Gitlab::Cache::Import::Caching).to receive(:set_includes?).twice.times.and_call_original
          mock_issue_serializer(1)

          job_waiter = subject.execute

          expect(job_waiter.jobs_remaining).to eq(1)
          expect(Gitlab::JiraImport.get_issues_next_start_at(project.id)).to eq(2)
        end
      end
    end
  end
end
