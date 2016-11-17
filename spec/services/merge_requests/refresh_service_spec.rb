require 'spec_helper'

describe MergeRequests::RefreshService, services: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:service) { MergeRequests::RefreshService }

  describe '#execute' do
    before do
      @user = create(:user)
      group = create(:group)
      group.add_owner(@user)

      @project = create(:project, namespace: group, approvals_before_merge: 1, reset_approvals_on_push: true)
      @fork_project = Projects::ForkService.new(@project, @user).execute
      # The call to project.repository.after_import in RepositoryForkWorker does
      # not reset the @exists variable of @fork_project.repository so we have to
      # explicitely call this method to clear the @exists variable.
      @fork_project.repository.after_import

      @merge_request = create(:merge_request,
                              source_project: @project,
                              source_branch: 'master',
                              target_branch: 'feature',
                              target_project: @project,
                              merge_when_build_succeeds: true,
                              merge_user: @user)

      @fork_merge_request = create(:merge_request,
                                   source_project: @fork_project,
                                   source_branch: 'master',
                                   target_branch: 'feature',
                                   target_project: @project)

      @merge_request.approvals.create(user_id: user.id)
      @fork_merge_request.approvals.create(user_id: user.id)

      @build_failed_todo = create(:todo,
                                  :build_failed,
                                  user: @user,
                                  project: @project,
                                  target: @merge_request,
                                  author: @user)

      @fork_build_failed_todo = create(:todo,
                                       :build_failed,
                                       user: @user,
                                       project: @project,
                                       target: @merge_request,
                                       author: @user)

      @commits = @merge_request.commits

      @oldrev = @commits.last.id
      @newrev = @commits.first.id
    end

    context 'push to origin repo source branch' do
      let(:refresh_service) { service.new(@project, @user) }
      before do
        allow(refresh_service).to receive(:execute_hooks)
        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs
      end

      it 'executes hooks with update action' do
        expect(refresh_service).to have_received(:execute_hooks).
          with(@merge_request, 'update', @oldrev)
      end

      it { expect(@merge_request.notes).not_to be_empty }
      it { expect(@merge_request).to be_open }
      it { expect(@merge_request.approvals).to be_empty }
      it { expect(@merge_request.merge_when_build_succeeds).to be_falsey }
      it { expect(@merge_request.diff_head_sha).to eq(@newrev) }
      it { expect(@fork_merge_request).to be_open }
      it { expect(@fork_merge_request.notes).to be_empty }
      it { expect(@build_failed_todo).to be_done }
      it { expect(@fork_build_failed_todo).to be_done }
      it { expect(@fork_merge_request.approvals).not_to be_empty }
    end

    context 'push to origin repo target branch' do
      before do
        service.new(@project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
        reload_mrs
      end

      it { expect(@merge_request.notes.last.note).to include('changed to merged') }
      it { expect(@merge_request).to be_merged }
      it { expect(@merge_request.approvals).not_to be_empty }
      it { expect(@fork_merge_request).to be_merged }
      it { expect(@fork_merge_request.notes.last.note).to include('changed to merged') }
      it { expect(@fork_merge_request.approvals).not_to be_empty }
      it { expect(@build_failed_todo).to be_done }
      it { expect(@fork_build_failed_todo).to be_done }
    end

    context 'manual merge of source branch' do
      before do
        # Merge master -> feature branch
        author = { email: 'test@gitlab.com', time: Time.now, name: "Me" }
        commit_options = { message: 'Test message', committer: author, author: author }
        @project.repository.merge(@user, @merge_request, commit_options)
        commit = @project.repository.commit('feature')
        service.new(@project, @user).execute(@oldrev, commit.id, 'refs/heads/feature')
        reload_mrs
      end

      it { expect(@merge_request.notes.last.note).to include('changed to merged') }
      it { expect(@merge_request).to be_merged }
      it { expect(@merge_request.diffs.size).to be > 0 }
      it { expect(@fork_merge_request).to be_merged }
      it { expect(@fork_merge_request.notes.last.note).to include('changed to merged') }
      it { expect(@build_failed_todo).to be_done }
      it { expect(@fork_build_failed_todo).to be_done }
    end

    context 'push to fork repo source branch' do
      let(:refresh_service) { service.new(@fork_project, @user) }
      before do
        allow(refresh_service).to receive(:execute_hooks)
        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs
      end

      it 'executes hooks with update action' do
        expect(refresh_service).to have_received(:execute_hooks).
          with(@fork_merge_request, 'update', @oldrev)
      end

      it { expect(@merge_request.notes).to be_empty }
      it { expect(@merge_request).to be_open }
      it { expect(@merge_request.approvals).not_to be_empty }
      it { expect(@fork_merge_request.notes.last.note).to include('Added 28 commits') }
      it { expect(@fork_merge_request).to be_open }
      it { expect(@build_failed_todo).to be_pending }
      it { expect(@fork_build_failed_todo).to be_pending }
      it { expect(@fork_merge_request.approvals).to be_empty }
    end

    context 'push to fork repo target branch' do
      before do
        service.new(@fork_project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
        reload_mrs
      end

      it { expect(@merge_request.notes).to be_empty }
      it { expect(@merge_request).to be_open }
      it { expect(@merge_request.approvals).not_to be_empty }
      it { expect(@fork_merge_request.notes).to be_empty }
      it { expect(@fork_merge_request).to be_open }
      it { expect(@build_failed_todo).to be_pending }
      it { expect(@fork_build_failed_todo).to be_pending }
      it { expect(@fork_merge_request.approvals).not_to be_empty }
    end

    context 'push to origin repo target branch after fork project was removed' do
      before do
        @fork_project.destroy
        service.new(@project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
        reload_mrs
      end

      it { expect(@merge_request.notes.last.note).to include('changed to merged') }
      it { expect(@merge_request).to be_merged }
      it { expect(@merge_request.approvals).not_to be_empty }
      it { expect(@fork_merge_request).to be_open }
      it { expect(@fork_merge_request.notes).to be_empty }
      it { expect(@build_failed_todo).to be_done }
      it { expect(@fork_build_failed_todo).to be_done }
      it { expect(@fork_merge_request.approvals).not_to be_empty }
    end

    context 'resetting approvals if they are enabled' do
      context 'when approvals_before_merge is disabled' do
        before do
          @project.update(approvals_before_merge: 0)
          refresh_service = service.new(@project, @user)
          allow(refresh_service).to receive(:execute_hooks)
          refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
          reload_mrs
        end

        it 'does not reset approvals' do
          expect(@merge_request.approvals).not_to be_empty
        end
      end

      context 'when approvals_before_merge is disabled' do
        before do
          @project.update(reset_approvals_on_push: false)
          refresh_service = service.new(@project, @user)
          allow(refresh_service).to receive(:execute_hooks)
          refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
          reload_mrs
        end

        it 'does not reset approvals' do
          expect(@merge_request.approvals).not_to be_empty
        end
      end

      context 'when the rebase_commit_sha on the MR matches the pushed SHA' do
        before do
          @merge_request.update(rebase_commit_sha: @newrev)
          refresh_service = service.new(@project, @user)
          allow(refresh_service).to receive(:execute_hooks)
          refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
          reload_mrs
        end

        it 'does not reset approvals' do
          expect(@merge_request.approvals).not_to be_empty
        end
      end

      context 'when there are approvals to be reset' do
        before do
          refresh_service = service.new(@project, @user)
          allow(refresh_service).to receive(:execute_hooks)
          refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
          reload_mrs
        end

        it 'resets the approvals' do
          expect(@merge_request.approvals).to be_empty
        end
      end
    end

    context 'push new branch that exists in a merge request' do
      let(:refresh_service) { service.new(@fork_project, @user) }

      it 'refreshes the merge request' do
        expect(refresh_service).to receive(:execute_hooks).
                                       with(@fork_merge_request, 'update', Gitlab::Git::BLANK_SHA)
        allow_any_instance_of(Repository).to receive(:merge_base).and_return(@oldrev)

        refresh_service.execute(Gitlab::Git::BLANK_SHA, @newrev, 'refs/heads/master')
        reload_mrs

        expect(@merge_request.notes).to be_empty
        expect(@merge_request).to be_open

        notes = @fork_merge_request.notes.reorder(:created_at).map(&:note)
        expect(notes[0]).to include('Restored source branch `master`')
        expect(notes[1]).to include('Added 28 commits')
        expect(@fork_merge_request).to be_open
      end
    end

    context 'merge request metrics' do
      let(:issue) { create :issue, project: @project }
      let(:commit_author) { create :user }
      let(:commit) { project.commit }

      before do
        project.team << [commit_author, :developer]
        project.team << [user, :developer]

        allow(commit).to receive_messages(
          safe_message: "Closes #{issue.to_reference}",
          references: [issue],
          author_name: commit_author.name,
          author_email: commit_author.email,
          committed_date: Time.now
        )

        allow_any_instance_of(MergeRequest).to receive(:commits).and_return([commit])
      end

      context 'when the merge request is sourced from the same project' do
        it 'creates a `MergeRequestsClosingIssues` record for each issue closed by a commit' do
          merge_request = create(:merge_request, target_branch: 'master', source_branch: 'feature', source_project: @project)
          refresh_service = service.new(@project, @user)
          allow(refresh_service).to receive(:execute_hooks)
          refresh_service.execute(@oldrev, @newrev, 'refs/heads/feature')

          issue_ids = MergeRequestsClosingIssues.where(merge_request: merge_request).pluck(:issue_id)
          expect(issue_ids).to eq([issue.id])
        end
      end

      context 'when the merge request is sourced from a different project' do
        it 'creates a `MergeRequestsClosingIssues` record for each issue closed by a commit' do
          forked_project = create(:project)
          create(:forked_project_link, forked_to_project: forked_project, forked_from_project: @project)

          merge_request = create(:merge_request,
                                 target_branch: 'master',
                                 source_branch: 'feature',
                                 target_project: @project,
                                 source_project: forked_project)
          refresh_service = service.new(@project, @user)
          allow(refresh_service).to receive(:execute_hooks)
          refresh_service.execute(@oldrev, @newrev, 'refs/heads/feature')

          issue_ids = MergeRequestsClosingIssues.where(merge_request: merge_request).pluck(:issue_id)
          expect(issue_ids).to eq([issue.id])
        end
      end
    end

    context 'when the source branch is deleted' do
      it 'does not create a MergeRequestDiff record' do
        refresh_service = service.new(@project, @user)

        expect do
          refresh_service.execute(@oldrev, Gitlab::Git::BLANK_SHA, 'refs/heads/master')
        end.not_to change { MergeRequestDiff.count }
      end
    end

    def reload_mrs
      @merge_request.reload
      @fork_merge_request.reload
      @build_failed_todo.reload
      @fork_build_failed_todo.reload
    end
  end
end
