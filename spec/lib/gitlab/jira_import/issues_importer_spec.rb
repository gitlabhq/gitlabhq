# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::IssuesImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include JiraIntegrationHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:jira_import) { create(:jira_import_state, project: project, user: current_user) }
  let_it_be(:default_issue_type) { WorkItems::Type.default_issue_type }

  let(:deployment_type) { 'cloud' }
  let(:jira_issue_1) { instance_double(JIRA::Resource::Issue, id: 'JIRA-1', attrs: { key: 'JIRA-1' }) }
  let(:jira_issue_2) { instance_double(JIRA::Resource::Issue, id: 'JIRA-2', attrs: { key: 'JIRA-2' }) }
  let(:jira_issues) { [jira_issue_1, jira_issue_2] }

  let(:jira_integration) do
    create(:jira_integration, project: project, url: 'https://jira.example.com', deployment_type: deployment_type)
  end

  subject { described_class.new(project) }

  before do
    stub_jira_integration_test
    allow(project).to receive(:jira_integration).and_return(jira_integration)
  end

  describe '#imported_items_cache_key' do
    it_behaves_like 'raise exception if not implemented'
    it { expect(subject.imported_items_cache_key).to eq("jira-importer/already-imported/#{project.id}/issues") }
  end

  describe '#execute' do
    context 'when no returned issues' do
      it 'does not schedule any import jobs' do
        response = ServiceResponse.success(payload: { issues: [], is_last: true, next_page_token: nil, page: 1 })
        expect_next_instance_of(Jira::Requests::Issues::CloudListService) do |service|
          expect(service).to receive(:execute).and_return(response)
        end

        expect(subject).not_to receive(:already_imported?)
        expect(subject).not_to receive(:mark_as_imported)
        expect(Gitlab::JiraImport::ImportIssueWorker).not_to receive(:perform_async)

        job_waiter = subject.execute

        expect(job_waiter.jobs_remaining).to eq(0)
        pagination_state = Gitlab::JiraImport.get_pagination_state(project.id)
        expect(pagination_state[:is_last]).to be true
      end
    end

    context 'with results returned' do
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

      context 'when using Jira Cloud' do
        let(:deployment_type) { 'cloud' }

        context 'when single page of results is returned' do
          before do
            stub_const("#{described_class.name}::BATCH_SIZE", 3)
          end

          it 'schedules 2 import jobs' do
            response = ServiceResponse.success(
              payload: { issues: jira_issues, is_last: true, next_page_token: 'token123', page: 1 }
            )
            expect_next_instance_of(Jira::Requests::Issues::CloudListService) do |service|
              expect(service).to receive(:execute).and_return(response)
            end

            expect(Gitlab::JiraImport::ImportIssueWorker).to receive(:perform_async).twice
            expect(Gitlab::Cache::Import::Caching).to receive(:set_add).twice.and_call_original
            expect(Gitlab::Cache::Import::Caching).to receive(:set_includes?).twice.and_call_original
            mock_issue_serializer(2)

            job_waiter = subject.execute

            expect(job_waiter.jobs_remaining).to eq(2)
            pagination_state = Gitlab::JiraImport.get_pagination_state(project.id)
            expect(pagination_state[:is_last]).to be true
          end
        end

        context 'when importing some issue raises an exception' do
          before do
            stub_const("#{described_class.name}::BATCH_SIZE", 3)
          end

          it 'schedules 1 import job and tracks exception' do
            response = ServiceResponse.success(
              payload: { issues: jira_issues, is_last: true, next_page_token: 'token123', page: 1 }
            )
            expect_next_instance_of(Jira::Requests::Issues::CloudListService) do |service|
              expect(service).to receive(:execute).and_return(response)
            end

            expect(Gitlab::JiraImport::ImportIssueWorker).to receive(:perform_async).once
            expect(Gitlab::Cache::Import::Caching).to receive(:set_add).once.and_call_original
            expect(Gitlab::Cache::Import::Caching).to receive(:set_includes?).twice.and_call_original
            expect(Gitlab::ErrorTracking).to receive(:track_exception).once
            mock_issue_serializer(2, raise_exception_on_even_mocks: true)

            job_waiter = subject.execute

            expect(job_waiter.jobs_remaining).to eq(1)
          end
        end

        context 'when duplicate results are returned' do
          before do
            stub_const("#{described_class.name}::BATCH_SIZE", 2)
          end

          it 'schedules 1 import job' do
            response = ServiceResponse.success(
              payload: { issues: [jira_issue_1, jira_issue_1], is_last: true, next_page_token: 'token123', page: 1 }
            )
            expect_next_instance_of(Jira::Requests::Issues::CloudListService) do |service|
              expect(service).to receive(:execute).and_return(response)
            end

            expect(Gitlab::JiraImport::ImportIssueWorker).to receive(:perform_async).once
            expect(Gitlab::Cache::Import::Caching).to receive(:set_add).once.and_call_original
            expect(Gitlab::Cache::Import::Caching).to receive(:set_includes?).twice.and_call_original
            mock_issue_serializer(1)

            job_waiter = subject.execute

            expect(job_waiter.jobs_remaining).to eq(1)
          end
        end
      end

      context 'when using Jira Server' do
        let(:deployment_type) { 'server' }

        context 'when single page of results is returned' do
          before do
            stub_const("#{described_class.name}::BATCH_SIZE", 3)
          end

          it 'schedules 2 import jobs' do
            response = ServiceResponse.success(
              payload: { issues: jira_issues, is_last: true, next_page_token: nil, page: 2 }
            )
            expect_next_instance_of(Jira::Requests::Issues::ServerListService) do |service|
              expect(service).to receive(:execute).and_return(response)
            end

            expect(Gitlab::JiraImport::ImportIssueWorker).to receive(:perform_async).twice
            expect(Gitlab::Cache::Import::Caching).to receive(:set_add).twice.and_call_original
            expect(Gitlab::Cache::Import::Caching).to receive(:set_includes?).twice.and_call_original
            mock_issue_serializer(2)

            job_waiter = subject.execute

            expect(job_waiter.jobs_remaining).to eq(2)
            pagination_state = Gitlab::JiraImport.get_pagination_state(project.id)
            expect(pagination_state[:is_last]).to be true
          end
        end

        context 'when importing some issue raises an exception' do
          before do
            stub_const("#{described_class.name}::BATCH_SIZE", 3)
          end

          it 'schedules 1 import job and tracks exception' do
            response = ServiceResponse.success(
              payload: { issues: jira_issues, is_last: true, next_page_token: nil, page: 2 }
            )
            expect_next_instance_of(Jira::Requests::Issues::ServerListService) do |service|
              expect(service).to receive(:execute).and_return(response)
            end

            expect(Gitlab::JiraImport::ImportIssueWorker).to receive(:perform_async).once
            expect(Gitlab::Cache::Import::Caching).to receive(:set_add).once.and_call_original
            expect(Gitlab::Cache::Import::Caching).to receive(:set_includes?).twice.and_call_original
            expect(Gitlab::ErrorTracking).to receive(:track_exception).once
            mock_issue_serializer(2, raise_exception_on_even_mocks: true)

            job_waiter = subject.execute

            expect(job_waiter.jobs_remaining).to eq(1)
          end
        end

        context 'when duplicate results are returned' do
          before do
            stub_const("#{described_class.name}::BATCH_SIZE", 2)
          end

          it 'schedules 1 import job' do
            response = ServiceResponse.success(
              payload: { issues: [jira_issue_1, jira_issue_1], is_last: true, next_page_token: nil, page: 2 }
            )
            expect_next_instance_of(Jira::Requests::Issues::ServerListService) do |service|
              expect(service).to receive(:execute).and_return(response)
            end

            expect(Gitlab::JiraImport::ImportIssueWorker).to receive(:perform_async).once
            expect(Gitlab::Cache::Import::Caching).to receive(:set_add).once.and_call_original
            expect(Gitlab::Cache::Import::Caching).to receive(:set_includes?).twice.and_call_original
            mock_issue_serializer(1)

            job_waiter = subject.execute

            expect(job_waiter.jobs_remaining).to eq(1)
          end
        end
      end
    end

    # New specs for HTTP-based service integration
    context 'when last page is already reached' do
      before do
        Gitlab::JiraImport.store_pagination_state(project.id, { is_last: true, next_page_token: nil, page: 1 })
      end

      it 'does not fetch issues' do
        expect(Jira::Requests::Issues::CloudListService).not_to receive(:new)
        expect(Jira::Requests::Issues::ServerListService).not_to receive(:new)

        job_waiter = subject.execute

        expect(job_waiter.jobs_remaining).to eq(0)
      end
    end

    context 'when service returns an error' do
      it 'does not schedule any jobs' do
        response = ServiceResponse.error(message: 'Connection failed')
        expect_next_instance_of(Jira::Requests::Issues::CloudListService) do |service|
          expect(service).to receive(:execute).and_return(response)
        end

        expect(Gitlab::JiraImport::ImportIssueWorker).not_to receive(:perform_async)

        job_waiter = subject.execute

        expect(job_waiter.jobs_remaining).to eq(0)
      end
    end
  end
end
