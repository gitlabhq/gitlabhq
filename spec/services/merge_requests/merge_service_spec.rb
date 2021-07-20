# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeService do
  include ExclusiveLeaseHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }

  let(:merge_request) { create(:merge_request, :simple, author: user2, assignees: [user2]) }
  let(:project) { merge_request.project }

  before do
    project.add_maintainer(user)
    project.add_developer(user2)
  end

  describe '#execute' do
    let(:service) { described_class.new(project: project, current_user: user, params: merge_params) }
    let(:merge_params) do
      { commit_message: 'Awesome message', sha: merge_request.diff_head_sha }
    end

    let(:lease_key) { "merge_requests_merge_service:#{merge_request.id}" }
    let!(:lease) { stub_exclusive_lease(lease_key) }

    context 'valid params' do
      before do
        allow(service).to receive(:execute_hooks)
        expect(merge_request).to receive(:update_and_mark_in_progress_merge_commit_sha).twice.and_call_original

        perform_enqueued_jobs do
          service.execute(merge_request)
        end
      end

      it { expect(merge_request).to be_valid }
      it { expect(merge_request).to be_merged }

      it 'persists merge_commit_sha and nullifies in_progress_merge_commit_sha' do
        expect(merge_request.merge_commit_sha).not_to be_nil
        expect(merge_request.in_progress_merge_commit_sha).to be_nil
      end

      it 'does not update squash_commit_sha if it is not a squash' do
        expect(merge_request.squash_commit_sha).to be_nil
      end

      it 'sends email to user2 about merge of new merge_request' do
        email = ActionMailer::Base.deliveries.last
        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(merge_request.title)
      end

      context 'note creation' do
        it 'creates resource state event about merge_request merge' do
          event = merge_request.resource_state_events.last
          expect(event.state).to eq('merged')
        end
      end

      context 'when squashing' do
        let(:merge_params) do
          { commit_message: 'Merge commit message',
            squash_commit_message: 'Squash commit message',
            sha: merge_request.diff_head_sha }
        end

        let(:merge_request) do
          # A merge request with 5 commits
          create(:merge_request, :simple,
                 author: user2,
                 assignees: [user2],
                 squash: true,
                 source_branch: 'improve/awesome',
                 target_branch: 'fix')
        end

        it 'merges the merge request with squashed commits' do
          expect(merge_request).to be_merged

          merge_commit = merge_request.merge_commit
          squash_commit = merge_request.merge_commit.parents.last

          expect(merge_commit.message).to eq('Merge commit message')
          expect(squash_commit.message).to eq("Squash commit message\n")
        end

        it 'persists squash_commit_sha' do
          squash_commit = merge_request.merge_commit.parents.last

          expect(merge_request.squash_commit_sha).to eq(squash_commit.id)
        end
      end
    end

    context 'running the service multiple time' do
      it 'is idempotent' do
        2.times { service.execute(merge_request) }

        expect(merge_request.merge_error).to be_falsey
        expect(merge_request).to be_valid
        expect(merge_request).to be_merged

        commit_messages = project.repository.commits('master', limit: 2).map(&:message)
        expect(commit_messages.uniq.size).to eq(2)
        expect(merge_request.in_progress_merge_commit_sha).to be_nil
      end
    end

    context 'when an invalid sha is passed' do
      let(:merge_request) do
        create(:merge_request, :simple,
               author: user2,
               assignees: [user2],
               squash: true,
               source_branch: 'improve/awesome',
               target_branch: 'fix')
      end

      let(:merge_params) do
        { sha: merge_request.commits.second.sha }
      end

      it 'does not merge the MR' do
        service.execute(merge_request)

        expect(merge_request).not_to be_merged
        expect(merge_request.merge_error).to match(/Branch has been updated/)
      end
    end

    context 'when the `sha` param is missing' do
      let(:merge_params) { {} }

      it 'returns the error' do
        merge_error = 'Branch has been updated since the merge was requested. '\
                      'Please review the changes.'

        expect { service.execute(merge_request) }
          .to change { merge_request.merge_error }
                .from(nil).to(merge_error)
      end
    end

    context 'closes related issues' do
      before do
        allow(project).to receive(:default_branch).and_return(merge_request.target_branch)
      end

      it 'closes GitLab issue tracker issues' do
        issue  = create :issue, project: project
        commit = instance_double('commit', safe_message: "Fixes #{issue.to_reference}", date: Time.current, authored_date: Time.current)
        allow(merge_request).to receive(:commits).and_return([commit])
        merge_request.cache_merge_request_closes_issues!

        service.execute(merge_request)

        expect(issue.reload.closed?).to be_truthy
      end

      context 'with Jira integration' do
        include JiraServiceHelper

        let(:jira_tracker) { project.create_jira_integration }
        let(:jira_issue)   { ExternalIssue.new('JIRA-123', project) }
        let(:commit)       { double('commit', safe_message: "Fixes #{jira_issue.to_reference}") }

        before do
          stub_jira_integration_test
          project.update!(has_external_issue_tracker: true)
          jira_integration_settings
          stub_jira_urls(jira_issue.id)
          allow(merge_request).to receive(:commits).and_return([commit])
        end

        it 'closes issues on Jira issue tracker' do
          jira_issue = ExternalIssue.new('JIRA-123', project)
          stub_jira_urls(jira_issue)
          commit = double('commit', safe_message: "Fixes #{jira_issue.to_reference}")
          allow(merge_request).to receive(:commits).and_return([commit])

          expect_any_instance_of(Integrations::Jira).to receive(:close_issue).with(merge_request, jira_issue, user).once

          service.execute(merge_request)
        end

        context 'wrong issue markdown' do
          it 'does not close issues on Jira issue tracker' do
            jira_issue = ExternalIssue.new('#JIRA-123', project)
            stub_jira_urls(jira_issue)
            commit = double('commit', safe_message: "Fixes #{jira_issue.to_reference}")
            allow(merge_request).to receive(:commits).and_return([commit])

            expect_any_instance_of(Integrations::Jira).not_to receive(:close_issue)

            service.execute(merge_request)
          end
        end
      end
    end

    context 'closes related todos' do
      let(:merge_request) { create(:merge_request, assignees: [user], author: user) }
      let(:project) { merge_request.project }

      let!(:todo) do
        create(:todo, :assigned,
          project: project,
          author: user,
          user: user,
          target: merge_request)
      end

      before do
        allow(service).to receive(:execute_hooks)

        perform_enqueued_jobs do
          service.execute(merge_request)
          todo.reload
        end
      end

      it { expect(todo).to be_done }
    end

    context 'source branch removal' do
      context 'when the source branch is protected' do
        let(:service) do
          described_class.new(project: project, current_user: user, params: merge_params.merge('should_remove_source_branch' => true))
        end

        before do
          create(:protected_branch, project: project, name: merge_request.source_branch)
        end

        it 'does not delete the source branch' do
          expect(::Branches::DeleteService).not_to receive(:new)

          service.execute(merge_request)
        end
      end

      context 'when the source branch is the default branch' do
        let(:service) do
          described_class.new(project: project, current_user: user, params: merge_params.merge('should_remove_source_branch' => true))
        end

        before do
          allow(project).to receive(:root_ref?).with(merge_request.source_branch).and_return(true)
        end

        it 'does not delete the source branch' do
          expect(::Branches::DeleteService).not_to receive(:new)
          service.execute(merge_request)
        end
      end

      context 'when the source branch can be removed' do
        context 'when MR author set the source branch to be removed' do
          before do
            merge_request.update_attribute(:merge_params, { 'force_remove_source_branch' => '1' })
          end

          it 'removes the source branch using the author user' do
            expect(::MergeRequests::DeleteSourceBranchWorker).to receive(:perform_async).with(merge_request.id, merge_request.source_branch_sha, merge_request.author.id)

            service.execute(merge_request)
          end

          context 'when the merger set the source branch not to be removed' do
            let(:service) { described_class.new(project: project, current_user: user, params: merge_params.merge('should_remove_source_branch' => false)) }

            it 'does not delete the source branch' do
              expect(::MergeRequests::DeleteSourceBranchWorker).not_to receive(:perform_async)

              service.execute(merge_request)
            end
          end
        end

        context 'when MR merger set the source branch to be removed' do
          let(:service) do
            described_class.new(project: project, current_user: user, params: merge_params.merge('should_remove_source_branch' => true))
          end

          it 'removes the source branch using the current user' do
            expect(::MergeRequests::DeleteSourceBranchWorker).to receive(:perform_async).with(merge_request.id, merge_request.source_branch_sha, user.id)

            service.execute(merge_request)
          end
        end
      end
    end

    context 'error handling' do
      before do
        allow(Gitlab::AppLogger).to receive(:error)
      end

      context 'when source is missing' do
        it 'logs and saves error' do
          allow(merge_request).to receive(:diff_head_sha) { nil }

          error_message = 'No source for merge'

          service.execute(merge_request)

          expect(merge_request.merge_error).to eq(error_message)
          expect(Gitlab::AppLogger).to have_received(:error).with(a_string_matching(error_message))
        end
      end

      it 'logs and saves error if there is an exception' do
        error_message = 'error message'

        allow(service).to receive(:repository).and_raise(error_message)
        allow(service).to receive(:execute_hooks)

        service.execute(merge_request)

        expect(merge_request.merge_error).to eq(described_class::GENERIC_ERROR_MESSAGE)
        expect(Gitlab::AppLogger).to have_received(:error).with(a_string_matching(error_message))
      end

      it 'logs and saves error if user is not authorized' do
        stub_exclusive_lease

        unauthorized_user = create(:user)
        project.add_reporter(unauthorized_user)

        service = described_class.new(project: project, current_user: unauthorized_user)

        service.execute(merge_request)

        expect(merge_request.merge_error)
          .to eq('You are not allowed to merge this merge request')
      end

      it 'logs and saves error if there is an PreReceiveError exception' do
        error_message = 'error message'

        allow(service).to receive(:repository).and_raise(Gitlab::Git::PreReceiveError, "GitLab: #{error_message}")
        allow(service).to receive(:execute_hooks)

        service.execute(merge_request)

        expect(merge_request.merge_error).to include('Something went wrong during merge pre-receive hook')
        expect(Gitlab::AppLogger).to have_received(:error).with(a_string_matching(error_message))
      end

      it 'logs and saves error if commit is not created' do
        allow_any_instance_of(Repository).to receive(:merge).and_return(false)
        allow(service).to receive(:execute_hooks)

        service.execute(merge_request)

        expect(merge_request).to be_open
        expect(merge_request.merge_commit_sha).to be_nil
        expect(merge_request.merge_error).to include(described_class::GENERIC_ERROR_MESSAGE)
        expect(Gitlab::AppLogger).to have_received(:error).with(a_string_matching(described_class::GENERIC_ERROR_MESSAGE))
      end

      context 'when squashing is required' do
        before do
          merge_request.update!(source_branch: 'master', target_branch: 'feature')
          merge_request.target_project.project_setting.squash_always!
        end

        it 'raises an error if squashing is not done' do
          error_message = 'requires squashing commits'

          service.execute(merge_request)

          expect(merge_request).to be_open

          expect(merge_request.merge_commit_sha).to be_nil
          expect(merge_request.squash_commit_sha).to be_nil
          expect(merge_request.merge_error).to include(error_message)
          expect(Gitlab::AppLogger).to have_received(:error).with(a_string_matching(error_message))
        end
      end

      context 'when squashing' do
        before do
          merge_request.update!(source_branch: 'master', target_branch: 'feature')
        end

        it 'logs and saves error if there is an error when squashing' do
          error_message = 'Failed to squash. Should be done manually'

          allow_any_instance_of(MergeRequests::SquashService).to receive(:squash!).and_return(nil)
          merge_request.update!(squash: true)

          service.execute(merge_request)

          expect(merge_request).to be_open
          expect(merge_request.merge_commit_sha).to be_nil
          expect(merge_request.squash_commit_sha).to be_nil
          expect(merge_request.merge_error).to include(error_message)
          expect(Gitlab::AppLogger).to have_received(:error).with(a_string_matching(error_message))
        end

        it 'logs and saves error if there is a squash in progress' do
          error_message = 'another squash is already in progress'

          allow_any_instance_of(MergeRequest).to receive(:squash_in_progress?).and_return(true)
          merge_request.update!(squash: true)

          service.execute(merge_request)

          expect(merge_request).to be_open
          expect(merge_request.merge_commit_sha).to be_nil
          expect(merge_request.squash_commit_sha).to be_nil
          expect(merge_request.merge_error).to include(error_message)
          expect(Gitlab::AppLogger).to have_received(:error).with(a_string_matching(error_message))
        end

        it 'logs and saves error if there is an PreReceiveError exception' do
          error_message = 'error message'

          allow(service).to receive(:repository).and_raise(Gitlab::Git::PreReceiveError, "GitLab: #{error_message}")
          allow(service).to receive(:execute_hooks)
          merge_request.update!(squash: true)

          service.execute(merge_request)

          expect(merge_request).to be_open
          expect(merge_request.merge_commit_sha).to be_nil
          expect(merge_request.squash_commit_sha).to be_nil
          expect(merge_request.merge_error).to include('Something went wrong during merge pre-receive hook')
          expect(Gitlab::AppLogger).to have_received(:error).with(a_string_matching(error_message))
        end

        context 'when fast-forward merge is not allowed' do
          before do
            allow_any_instance_of(Repository).to receive(:ancestor?).and_return(nil)
          end

          %w(semi-linear ff).each do |merge_method|
            it "logs and saves error if merge is #{merge_method} only" do
              merge_method = 'rebase_merge' if merge_method == 'semi-linear'
              merge_request.project.update!(merge_method: merge_method)
              error_message = 'Only fast-forward merge is allowed for your project. Please update your source branch'
              allow(service).to receive(:execute_hooks)
              expect(lease).to receive(:cancel)

              service.execute(merge_request)

              expect(merge_request).to be_open
              expect(merge_request.merge_commit_sha).to be_nil
              expect(merge_request.squash_commit_sha).to be_nil
              expect(merge_request.merge_error).to include(error_message)
              expect(Gitlab::AppLogger).to have_received(:error).with(a_string_matching(error_message))
            end
          end
        end
      end

      context 'when not mergeable' do
        let!(:error_message) { 'Merge request is not mergeable' }

        context 'with failing CI' do
          before do
            allow(merge_request).to receive(:mergeable_ci_state?) { false }
          end

          it 'logs and saves error' do
            service.execute(merge_request)

            expect(Gitlab::AppLogger).to have_received(:error).with(a_string_matching(error_message))
          end
        end

        context 'with unresolved discussions' do
          before do
            allow(merge_request).to receive(:mergeable_discussions_state?) { false }
          end

          it 'logs and saves error' do
            service.execute(merge_request)

            expect(Gitlab::AppLogger).to have_received(:error).with(a_string_matching(error_message))
          end

          context 'when passing `skip_discussions_check: true` as `options` parameter' do
            it 'merges the merge request' do
              service.execute(merge_request, skip_discussions_check: true)

              expect(merge_request).to be_valid
              expect(merge_request).to be_merged
            end
          end
        end
      end
    end

    context 'when the other sidekiq worker has already been running' do
      before do
        stub_exclusive_lease_taken(lease_key)
      end

      it 'does not execute service' do
        expect(service).not_to receive(:commit)

        service.execute(merge_request)
      end
    end
  end
end
