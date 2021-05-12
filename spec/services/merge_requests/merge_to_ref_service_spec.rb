# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeToRefService do
  shared_examples_for 'MergeService for target ref' do
    it 'target_ref has the same state of target branch' do
      repo = merge_request.target_project.repository

      process_merge_to_ref
      merge_service.execute(merge_request)

      ref_commits = repo.commits(merge_request.merge_ref_path, limit: 3)
      target_branch_commits = repo.commits(merge_request.target_branch, limit: 3)

      ref_commits.zip(target_branch_commits).each do |ref_commit, target_branch_commit|
        expect(ref_commit.parents).to eq(target_branch_commit.parents)
      end
    end
  end

  shared_examples_for 'successfully merges to ref with merge method' do
    it 'writes commit to merge ref' do
      repository = project.repository

      expect(repository.ref_exists?(target_ref)).to be(false)

      result = service.execute(merge_request)

      ref_head = repository.commit(target_ref)

      expect(result[:status]).to eq(:success)
      expect(result[:commit_id]).to be_present
      expect(result[:source_id]).to eq(merge_request.source_branch_sha)
      expect(result[:target_id]).to eq(repository.commit(first_parent_ref).sha)
      expect(repository.ref_exists?(target_ref)).to be(true)
      expect(ref_head.id).to eq(result[:commit_id])
    end
  end

  shared_examples_for 'successfully evaluates pre-condition checks' do
    it 'returns an error when the failing to process the merge' do
      allow(project.repository).to receive(:merge_to_ref).and_return(nil)

      result = service.execute(merge_request)

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Conflicts detected during merge')
    end

    it 'does not send any mail' do
      expect { process_merge_to_ref }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it 'does not change the MR state' do
      expect { process_merge_to_ref }.not_to change { merge_request.state }
    end

    it 'does not create notes' do
      expect { process_merge_to_ref }.not_to change { merge_request.notes.count }
    end

    it 'does not delete the source branch' do
      expect(::Branches::DeleteService).not_to receive(:new)

      process_merge_to_ref
    end
  end

  let_it_be(:user) { create(:user) }

  let(:merge_request) { create(:merge_request, :simple) }
  let(:project) { merge_request.project }

  describe '#execute' do
    let(:service) do
      described_class.new(project: project, current_user: user, params: params)
    end

    let(:params) { { commit_message: 'Awesome message', should_remove_source_branch: true, sha: merge_request.diff_head_sha } }

    def process_merge_to_ref
      perform_enqueued_jobs do
        service.execute(merge_request)
      end
    end

    it_behaves_like 'successfully merges to ref with merge method' do
      let(:first_parent_ref) { 'refs/heads/master' }
      let(:target_ref) { merge_request.merge_ref_path }
    end

    it_behaves_like 'successfully evaluates pre-condition checks'

    it 'returns an error when Gitlab::Git::CommandError is raised during merge' do
      allow(project.repository).to receive(:merge_to_ref) do
        raise Gitlab::Git::CommandError, 'Failed to create merge commit'
      end

      result = service.execute(merge_request)

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Failed to create merge commit')
    end

    context 'commit history comparison with regular MergeService' do
      before do
        # The merge service needs an authorized user while merge-to-ref
        # doesn't.
        project.add_maintainer(user)
      end

      let(:merge_ref_service) do
        described_class.new(project: project, current_user: user)
      end

      let(:merge_service) do
        MergeRequests::MergeService.new(project: project, current_user: user, params: { sha: merge_request.diff_head_sha })
      end

      context 'when merge commit' do
        it_behaves_like 'MergeService for target ref'
      end

      context 'when merge commit with squash' do
        before do
          merge_request.update!(squash: true)
        end

        it_behaves_like 'MergeService for target ref'

        it 'does not squash before merging' do
          expect(MergeRequests::SquashService).not_to receive(:new)

          process_merge_to_ref
        end
      end
    end

    context 'merge pre-condition checks' do
      before do
        merge_request.project.update!(merge_method: merge_method)
      end

      context 'when semi-linear merge method' do
        let(:merge_method) { :rebase_merge }

        it_behaves_like 'successfully merges to ref with merge method' do
          let(:first_parent_ref) { 'refs/heads/master' }
          let(:target_ref) { merge_request.merge_ref_path }
        end

        it_behaves_like 'successfully evaluates pre-condition checks'
      end

      context 'when fast-forward merge method' do
        let(:merge_method) { :ff }

        it_behaves_like 'successfully merges to ref with merge method' do
          let(:first_parent_ref) { 'refs/heads/master' }
          let(:target_ref) { merge_request.merge_ref_path }
        end

        it_behaves_like 'successfully evaluates pre-condition checks'
      end

      context 'when MR is not mergeable to ref' do
        let(:merge_method) { :merge }

        it 'returns error' do
          allow(project).to receive_message_chain(:repository, :merge_to_ref) { nil }

          error_message = 'Conflicts detected during merge'

          result = service.execute(merge_request)

          expect(result[:status]).to eq(:error)
          expect(result[:message]).to eq(error_message)
        end
      end
    end

    context 'does not close related todos' do
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

      it { expect(todo).not_to be_done }
    end

    context 'when source is missing' do
      it 'returns error' do
        allow(merge_request).to receive(:diff_head_sha) { nil }

        error_message = 'No source for merge'

        result = service.execute(merge_request)

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq(error_message)
      end
    end

    context 'when target ref is passed as a parameter' do
      let(:params) { { commit_message: 'merge train', target_ref: target_ref, sha: merge_request.diff_head_sha } }

      it_behaves_like 'successfully merges to ref with merge method' do
        let(:first_parent_ref) { 'refs/heads/master' }
        let(:target_ref) { 'refs/merge-requests/1/train' }
      end
    end

    describe 'cascading merge refs' do
      let_it_be(:project) { create(:project, :repository) }

      let(:params) { { commit_message: 'Cascading merge', first_parent_ref: first_parent_ref, target_ref: target_ref, sha: merge_request.diff_head_sha } }

      context 'when first merge happens' do
        let(:merge_request) do
          create(:merge_request, source_project: project, source_branch: 'feature',
                                 target_project: project, target_branch: 'master')
        end

        it_behaves_like 'successfully merges to ref with merge method' do
          let(:first_parent_ref) { 'refs/heads/master' }
          let(:target_ref) { 'refs/merge-requests/1/train' }
        end

        context 'when second merge happens' do
          let(:merge_request) do
            create(:merge_request, source_project: project, source_branch: 'improve/awesome',
                                   target_project: project, target_branch: 'master')
          end

          it_behaves_like 'successfully merges to ref with merge method' do
            let(:first_parent_ref) { 'refs/merge-requests/1/train' }
            let(:target_ref) { 'refs/merge-requests/2/train' }
          end
        end
      end
    end

    context 'allow conflicts to be merged in diff' do
      let(:params) { { allow_conflicts: true } }

      it 'calls merge_to_ref with allow_conflicts param' do
        expect(project.repository).to receive(:merge_to_ref) do |user, **kwargs|
          expect(kwargs[:allow_conflicts]).to eq(true)
        end.and_call_original

        service.execute(merge_request)
      end
    end
  end
end
