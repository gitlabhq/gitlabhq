# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeService, feature_category: :code_review_workflow do
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

    shared_examples 'with valid params' do
      before do
        merge_request.update!(merge_jid: 'abc123')
        allow(service).to receive(:execute_hooks)
        expect(merge_request).to receive(:update_and_mark_in_progress_merge_commit_sha).twice.and_call_original

        perform_enqueued_jobs do
          service.execute(merge_request)
        end
      end

      it { expect(merge_request).to be_valid }
      it { expect(merge_request).to be_merged }

      it 'does not update squash_commit_sha if it is not a squash' do
        expect(merge_request.squash_commit_sha).to be_nil
      end

      it 'sends email to user2 about merge of new merge_request' do
        email = ActionMailer::Base.deliveries.last
        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(merge_request.title)
      end

      it 'clears merge_jid' do
        expect(merge_request.reload.merge_jid).to be_nil
      end

      context 'note creation' do
        it 'creates resource state event about merge_request merge' do
          event = merge_request.resource_state_events.last
          expect(event.state).to eq('merged')
        end
      end
    end

    shared_examples 'squashing' do
      # A merge request with 5 commits
      let(:merge_request) do
        create(
          :merge_request,
          :simple,
          author: user2,
          assignees: [user2],
          squash: true,
          source_branch: 'improve/awesome',
          target_branch: 'fix'
        )
      end

      let(:merge_params) do
        { commit_message: 'Merge commit message',
          squash_commit_message: 'Squash commit message',
          sha: merge_request.diff_head_sha }
      end

      before do
        allow(service).to receive(:execute_hooks)
        expect(merge_request).to receive(:update_and_mark_in_progress_merge_commit_sha).twice.and_call_original

        perform_enqueued_jobs do
          service.execute(merge_request)
        end
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

    context 'when merge strategy is merge commit' do
      it 'persists merge_commit_sha and merged_commit_sha and nullifies in_progress_merge_commit_sha' do
        service.execute(merge_request)

        expect(merge_request.merge_commit_sha).not_to be_nil
        expect(merge_request.merged_commit_sha).to eq merge_request.merge_commit_sha
        expect(merge_request.in_progress_merge_commit_sha).to be_nil
      end

      it_behaves_like 'with valid params'

      it_behaves_like 'squashing'
    end

    context 'when merge strategy is fast forward' do
      before do
        project.update!(merge_requests_ff_only_enabled: true)
      end

      let(:merge_request) do
        create(
          :merge_request,
          source_branch: 'flatten-dir',
          target_branch: 'improve/awesome',
          assignees: [user2],
          author: create(:user)
        )
      end

      it 'does not create merge_commit_sha, but persists merged_commit_sha and nullifies in_progress_merge_commit_sha' do
        service.execute(merge_request)

        expect(merge_request.merge_commit_sha).to be_nil
        expect(merge_request.merged_commit_sha).not_to be_nil
        expect(merge_request.merged_commit_sha).to eq merge_request.diff_head_sha
        expect(merge_request.in_progress_merge_commit_sha).to be_nil
      end

      it_behaves_like 'with valid params'

      it 'updates squash_commit_sha and merged_commit_sha if it is a squash' do
        expect(merge_request).to receive(:update_and_mark_in_progress_merge_commit_sha).twice.and_call_original

        merge_request.update!(squash: true)

        expect { service.execute(merge_request) }
          .to change { merge_request.squash_commit_sha }
                .from(nil)

        expect(merge_request.merge_commit_sha).to be_nil
        expect(merge_request.merged_commit_sha).to eq merge_request.squash_commit_sha
        expect(merge_request.in_progress_merge_commit_sha).to be_nil
      end
    end

    context 'running the service once' do
      let(:ref) { merge_request.to_reference(full: true) }
      let(:jid) { SecureRandom.hex }

      let(:messages) do
        [
          /#{ref} - Git merge started on JID #{jid}/,
          /#{ref} - Git merge finished on JID #{jid}/,
          /#{ref} - Post merge started on JID #{jid}/,
          /#{ref} - Post merge finished on JID #{jid}/,
          /#{ref} - Merge process finished on JID #{jid}/
        ]
      end

      before do
        merge_request.update!(merge_jid: jid)
        ::Gitlab::ApplicationContext.push(caller_id: 'MergeWorker')
      end

      it 'logs status messages' do
        allow(Gitlab::AppLogger).to receive(:info).and_call_original

        messages.each do |message|
          expect(Gitlab::AppLogger).to receive(:info).with(
            hash_including(
              'meta.caller_id' => 'MergeWorker',
              message: message,
              merge_request_info: ref
            )
          ).and_call_original
        end

        service.execute(merge_request)
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
        create(
          :merge_request,
          :simple,
          author: user2,
          assignees: [user2],
          squash: true,
          source_branch: 'improve/awesome',
          target_branch: 'fix'
        )
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

    context 'closes related issues', :sidekiq_inline do
      let_it_be_with_refind(:group) { create(:group) }
      let_it_be_with_refind(:other_project) { create(:project, group: group) }
      let_it_be(:other_issue) { create(:issue, project: other_project) }
      let_it_be(:group_issue) { create(:issue, :group_level, namespace: group) }
      let(:issue1) { create(:issue, project: project) }
      let(:issue2) { create(:issue, project: project) }
      let(:commit) do
        double('commit', safe_message: "Fixes #{issue1.to_reference}", date: Time.current, authored_date: Time.current)
      end

      before do
        allow(project).to receive(:default_branch).and_return(merge_request.target_branch)
        allow(merge_request).to receive(:commits).and_return([commit])
        create(
          :merge_requests_closing_issues,
          issue: issue2,
          merge_request: merge_request,
          from_mr_description: false
        )
      end

      it 'closes GitLab issue tracker issues' do
        merge_request.cache_merge_request_closes_issues!

        expect do
          service.execute(merge_request)
        end.to change { issue1.reload.closed? }.from(false).to(true).and(
          change { issue2.reload.closed? }.from(false).to(true)
        )
      end

      context 'when closing issues exist in a namespace the merging user doesn\'t have access to' do
        context 'when the closing work item was created in the merge request description' do
          before do
            create(
              :merge_requests_closing_issues,
              issue: other_issue,
              merge_request: merge_request,
              from_mr_description: true
            )
            create(
              :merge_requests_closing_issues,
              issue: group_issue,
              merge_request: merge_request,
              from_mr_description: true
            )
          end

          it 'does not close the related issues' do
            merge_request.cache_merge_request_closes_issues!

            expect do
              service.execute(merge_request)
            end.to not_change { other_issue.reload.opened? }.from(true).and(
              not_change { group_issue.reload.opened? }.from(true)
            )
          end
        end

        context 'when the closing work item was not created in the merge request description' do
          before do
            create(
              :merge_requests_closing_issues,
              issue: other_issue,
              merge_request: merge_request,
              from_mr_description: false
            )
            create(
              :merge_requests_closing_issues,
              issue: group_issue,
              merge_request: merge_request,
              from_mr_description: false
            )
          end

          it 'closes the related issues' do
            merge_request.cache_merge_request_closes_issues!

            expect do
              service.execute(merge_request)
            end.to change { other_issue.reload.opened? }.from(true).to(false).and(
              # Autoclose is disabled for group level issues until we introduce a setting at the grouo level
              # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/472907
              not_change { group_issue.reload.opened? }.from(true)
            )
          end
        end
      end

      context 'when issue project has auto close disabled' do
        before_all do
          other_project.update!(autoclose_referenced_issues: false)
          group.add_developer(user)
        end

        before do
          create(
            :merge_requests_closing_issues,
            issue: other_issue,
            merge_request: merge_request,
            from_mr_description: false
          )
          create(
            :merge_requests_closing_issues,
            issue: group_issue,
            merge_request: merge_request,
            from_mr_description: false
          )
        end

        it 'only closes project issues where the setting is enabled' do
          merge_request.cache_merge_request_closes_issues!

          expect do
            service.execute(merge_request)
          end.to change { issue1.reload.closed? }.from(false).to(true).and(
            change { issue2.reload.closed? }.from(false).to(true)
          ).and(
            not_change { other_issue.reload.opened? }.from(true)
          ).and(
            not_change { group_issue.reload.opened? }.from(true)
          )
        end
      end

      context 'with Jira integration' do
        include JiraIntegrationHelpers

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

          it 'removes the source branch using the current user' do
            expect(::MergeRequests::DeleteSourceBranchWorker).to receive(:perform_async).with(merge_request.id, merge_request.source_branch_sha, user.id)

            service.execute(merge_request)

            expect(merge_request.reload.should_remove_source_branch?).to be nil
          end

          context 'when the merger set the source branch not to be removed' do
            let(:service) { described_class.new(project: project, current_user: user, params: merge_params.merge('should_remove_source_branch' => false)) }

            it 'does not delete the source branch' do
              expect(::MergeRequests::DeleteSourceBranchWorker).not_to receive(:perform_async)

              service.execute(merge_request)

              expect(merge_request.reload.should_remove_source_branch?).to be false
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

            expect(merge_request.reload.should_remove_source_branch?).to be true
          end

          context 'when switch_deletion_branch_user is false' do
            before do
              stub_feature_flags(switch_deletion_branch_user: false)
            end

            it 'removes the source branch using the current user' do
              expect(::MergeRequests::DeleteSourceBranchWorker).to receive(:perform_async).with(merge_request.id, merge_request.source_branch_sha, user.id)

              service.execute(merge_request)

              expect(merge_request.reload.should_remove_source_branch?).to be true
            end
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
          expect(Gitlab::AppLogger).to have_received(:error).with(
            hash_including(
              merge_request_info: merge_request.to_reference(full: true),
              message: a_string_matching(error_message)
            )
          )
        end
      end

      it 'logs and saves error if there is an exception' do
        error_message = 'error message'

        allow_next_instance_of(MergeRequests::MergeStrategies::FromSourceBranch) do |strategy|
          allow(strategy).to receive(:execute_git_merge!).and_raise(error_message)
        end

        service.execute(merge_request)

        expect(merge_request.merge_error).to eq(described_class::GENERIC_ERROR_MESSAGE)
        expect(Gitlab::AppLogger).to have_received(:error).with(
          hash_including(
            merge_request_info: merge_request.to_reference(full: true),
            message: a_string_matching(error_message)
          )
        )
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

        allow_next_instance_of(MergeRequests::MergeStrategies::FromSourceBranch) do |strategy|
          allow(strategy).to receive(:execute_git_merge!).and_raise(Gitlab::Git::PreReceiveError, "GitLab: #{error_message}")
        end

        service.execute(merge_request)

        expect(merge_request.merge_error).to include('Something went wrong during merge pre-receive hook')
        expect(Gitlab::AppLogger).to have_received(:error).with(
          hash_including(
            merge_request_info: merge_request.to_reference(full: true),
            message: a_string_matching(error_message)
          )
        )
      end

      it 'logs and saves error if commit is not created' do
        allow_any_instance_of(Repository).to receive(:merge).and_return(false)
        allow(service).to receive(:execute_hooks)

        service.execute(merge_request)

        expect(merge_request).to be_open
        expect(merge_request.merge_commit_sha).to be_nil
        expect(merge_request.merge_error).to include(described_class::GENERIC_ERROR_MESSAGE)
        expect(Gitlab::AppLogger).to have_received(:error).with(
          hash_including(
            merge_request_info: merge_request.to_reference(full: true),
            message: a_string_matching(described_class::GENERIC_ERROR_MESSAGE)
          )
        )
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
          expect(Gitlab::AppLogger).to have_received(:error).with(
            hash_including(
              merge_request_info: merge_request.to_reference(full: true),
              message: a_string_matching(error_message)
            )
          )
        end
      end

      context 'when squashing' do
        before do
          merge_request.update!(source_branch: 'master', target_branch: 'feature')
        end

        it 'logs and saves error if there is an error when squashing' do
          error_message = 'Squashing failed: Squash the commits locally, resolve any conflicts, then push the branch.'

          allow_any_instance_of(MergeRequests::SquashService).to receive(:squash!).and_return(nil)
          merge_request.update!(squash: true)

          service.execute(merge_request)

          expect(merge_request).to be_open
          expect(merge_request.merge_commit_sha).to be_nil
          expect(merge_request.squash_commit_sha).to be_nil
          expect(merge_request.merge_error).to include(error_message)
          expect(Gitlab::AppLogger).to have_received(:error).with(
            hash_including(
              merge_request_info: merge_request.to_reference(full: true),
              message: a_string_matching(error_message)
            )
          )
        end

        it 'logs and saves error if there is an PreReceiveError exception' do
          error_message = 'error message'

          allow_next_instance_of(MergeRequests::MergeStrategies::FromSourceBranch) do |strategy|
            allow(strategy).to receive(:execute_git_merge!).and_raise(Gitlab::Git::PreReceiveError, "GitLab: #{error_message}")
          end
          merge_request.update!(squash: true)

          service.execute(merge_request)

          expect(merge_request).to be_open
          expect(merge_request.merge_commit_sha).to be_nil
          expect(merge_request.squash_commit_sha).to be_nil
          expect(merge_request.merge_error).to include('Something went wrong during merge pre-receive hook')
          expect(Gitlab::AppLogger).to have_received(:error).with(
            hash_including(
              merge_request_info: merge_request.to_reference(full: true),
              message: a_string_matching(error_message)
            )
          )
        end

        context 'when fast-forward merge is not allowed' do
          before do
            allow_any_instance_of(Repository).to receive(:ancestor?).and_return(nil)
          end

          %w[semi-linear ff].each do |merge_method|
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
              expect(Gitlab::AppLogger).to have_received(:error).with(
                hash_including(
                  merge_request_info: merge_request.to_reference(full: true),
                  message: a_string_matching(error_message)
                )
              )
            end
          end
        end
      end

      context 'when not mergeable' do
        let!(:error_message) { 'Merge request is not mergeable' }

        context 'with failing CI' do
          before do
            allow(merge_request.project).to receive(:only_allow_merge_if_pipeline_succeeds) { true }
            allow_next_instance_of(MergeRequests::Mergeability::CheckCiStatusService) do |check|
              allow(check).to receive(:mergeable_ci_state?).and_return(false)
            end
          end

          it 'logs and saves error' do
            service.execute(merge_request)

            expect(Gitlab::AppLogger).to have_received(:error).with(
              hash_including(
                merge_request_info: merge_request.to_reference(full: true),
                message: a_string_matching(error_message)
              )
            )
          end
        end

        context 'with unresolved discussions' do
          before do
            allow(merge_request.project).to receive(:only_allow_merge_if_all_discussions_are_resolved) { true }
            allow(merge_request).to receive(:mergeable_discussions_state?) { false }
          end

          it 'logs and saves error' do
            service.execute(merge_request)

            expect(Gitlab::AppLogger).to have_received(:error).with(
              hash_including(
                merge_request_info: merge_request.to_reference(full: true),
                message: a_string_matching(error_message)
              )
            )
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

      context 'when passing `check_mergeability_retry_lease: true` as `options` parameter' do
        it 'call mergeable? with check_mergeability_retry_lease' do
          expect(merge_request).to receive(:mergeable?).with(hash_including(check_mergeability_retry_lease: true)).and_call_original

          service.execute(merge_request, check_mergeability_retry_lease: true)
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
