# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProcessCommitWorker do
  let(:worker) { described_class.new }
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:issue) { create(:issue, project: project, author: user) }
  let(:commit) { project.commit }

  describe '#perform' do
    it 'does not process the commit when the project does not exist' do
      expect(worker).not_to receive(:close_issues)

      worker.perform(-1, user.id, commit.to_hash)
    end

    it 'does not process the commit when the user does not exist' do
      expect(worker).not_to receive(:close_issues)

      worker.perform(project.id, -1, commit.to_hash)
    end

    include_examples 'an idempotent worker' do
      subject do
        perform_multiple([project.id, user.id, commit.to_hash], worker: worker)
      end

      it 'processes the commit message' do
        expect(worker).to receive(:process_commit_message)
          .exactly(IdempotentWorkerHelper::WORKER_EXEC_TIMES)
          .and_call_original

        subject
      end

      it 'updates the issue metrics' do
        expect(worker).to receive(:update_issue_metrics)
          .exactly(IdempotentWorkerHelper::WORKER_EXEC_TIMES)
          .and_call_original

        subject
      end
    end
  end

  describe '#process_commit_message' do
    context 'when pushing to the default branch' do
      before do
        allow(commit).to receive(:safe_message).and_return("Closes #{issue.to_reference}")
      end

      it 'closes issues that should be closed per the commit message' do
        expect(worker).to receive(:close_issues).with(project, user, user, commit, [issue])

        worker.process_commit_message(project, commit, user, user, true)
      end

      it 'creates cross references' do
        expect(commit).to receive(:create_cross_references!).with(user, [issue])

        worker.process_commit_message(project, commit, user, user, true)
      end
    end

    context 'when pushing to a non-default branch' do
      it 'does not close any issues' do
        allow(commit).to receive(:safe_message).and_return("Closes #{issue.to_reference}")

        expect(worker).not_to receive(:close_issues)

        worker.process_commit_message(project, commit, user, user, false)
      end

      it 'does not create cross references' do
        expect(commit).to receive(:create_cross_references!).with(user, [])

        worker.process_commit_message(project, commit, user, user, false)
      end
    end

    context 'when commit is a merge request merge commit to the default branch' do
      let(:merge_request) do
        create(:merge_request,
               description: "Closes #{issue.to_reference}",
               source_branch: 'feature-merged',
               target_branch: 'master',
               source_project: project)
      end

      let(:commit) do
        project.repository.create_branch('feature-merged', 'feature')
        project.repository.after_create_branch

        MergeRequests::MergeService
          .new(project: project, current_user: merge_request.author, params: { sha: merge_request.diff_head_sha })
          .execute(merge_request)

        merge_request.reload.merge_commit
      end

      it 'does not close any issues from the commit message' do
        expect(worker).not_to receive(:close_issues)

        worker.process_commit_message(project, commit, user, user, true)
      end

      it 'still creates cross references' do
        expect(commit).to receive(:create_cross_references!).with(user, [])

        worker.process_commit_message(project, commit, user, user, true)
      end
    end
  end

  describe '#close_issues' do
    context 'when the user can update the issues' do
      it 'closes the issues' do
        worker.close_issues(project, user, user, commit, [issue])

        issue.reload

        expect(issue.closed?).to eq(true)
      end
    end

    context 'when the user can not update the issues' do
      it 'does not close the issues' do
        other_user = create(:user)

        worker.close_issues(project, other_user, other_user, commit, [issue])

        issue.reload

        expect(issue.closed?).to eq(false)
      end
    end
  end

  describe '#update_issue_metrics', :clean_gitlab_redis_cache do
    context 'when commit has issue reference' do
      subject(:update_metrics_and_reload) do
        -> {
          worker.update_issue_metrics(commit, user)
          issue.metrics.reload
        }
      end

      before do
        allow(commit).to receive(:safe_message).and_return("Closes #{issue.to_reference}")
      end

      context 'when issue has no first_mentioned_in_commit_at set' do
        it 'updates issue metrics' do
          expect(update_metrics_and_reload)
            .to change { issue.metrics.first_mentioned_in_commit_at }.to(commit.committed_date)
        end
      end

      context 'when issue has first_mentioned_in_commit_at earlier than given committed_date' do
        before do
          issue.metrics.update!(first_mentioned_in_commit_at: commit.committed_date - 1.day)
        end

        it "doesn't update issue metrics" do
          expect(update_metrics_and_reload).not_to change { issue.metrics.first_mentioned_in_commit_at }
        end
      end

      context 'when issue has first_mentioned_in_commit_at later than given committed_date' do
        before do
          issue.metrics.update!(first_mentioned_in_commit_at: commit.committed_date + 1.day)
        end

        it "doesn't update issue metrics" do
          expect(update_metrics_and_reload)
            .to change { issue.metrics.first_mentioned_in_commit_at }.to(commit.committed_date)
        end
      end
    end

    context 'when commit has no issue references' do
      it "doesn't execute any queries with false conditions" do
        allow(commit).to receive(:safe_message).and_return("Lorem Ipsum")

        expect { worker.update_issue_metrics(commit, user) }
          .not_to make_queries_matching(/WHERE (?:1=0|0=1)/)
      end
    end
  end

  describe '#build_commit' do
    it 'returns a Commit' do
      commit = worker.build_commit(project, id: '123')

      expect(commit).to be_an_instance_of(Commit)
    end

    it 'parses date strings into Time instances' do
      commit = worker.build_commit(project,
                                   id: '123',
                                   authored_date: Time.current.to_s)

      expect(commit.authored_date).to be_a_kind_of(Time)
    end
  end
end
