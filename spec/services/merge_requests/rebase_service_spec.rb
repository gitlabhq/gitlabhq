# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::RebaseService do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:merge_request) do
    create(:merge_request,
           source_branch: 'feature_conflict',
           target_branch: 'master')
  end
  let(:project) { merge_request.project }
  let(:repository) { project.repository.raw }

  subject(:service) { described_class.new(project, user, {}) }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    context 'when another rebase is already in progress' do
      before do
        allow(merge_request).to receive(:rebase_in_progress?).and_return(true)
      end

      it 'saves the error message' do
        subject.execute(merge_request)

        expect(merge_request.reload.merge_error).to eq 'Rebase task canceled: Another rebase is already in progress'
      end

      it 'returns an error' do
        expect(service.execute(merge_request)).to match(status: :error,
                                                        message: described_class::REBASE_ERROR)
      end
    end

    shared_examples 'sequence of failure and success' do
      it 'properly clears the error message' do
        allow(repository).to receive(:gitaly_operation_client).and_raise('Something went wrong')

        service.execute(merge_request)

        expect(merge_request.reload.merge_error).to eq described_class::REBASE_ERROR

        allow(repository).to receive(:gitaly_operation_client).and_call_original

        service.execute(merge_request)

        expect(merge_request.reload.merge_error).to eq nil
      end
    end

    it_behaves_like 'sequence of failure and success'

    context 'with deprecated step rebase feature' do
      before do
        stub_feature_flags(two_step_rebase: false)
      end

      it_behaves_like 'sequence of failure and success'
    end

    context 'when unexpected error occurs' do
      before do
        allow(repository).to receive(:gitaly_operation_client).and_raise('Something went wrong')
      end

      it 'saves a generic error message' do
        subject.execute(merge_request)

        expect(merge_request.reload.merge_error).to eq described_class::REBASE_ERROR
      end

      it 'returns an error' do
        expect(service.execute(merge_request)).to match(status: :error,
                                                        message: described_class::REBASE_ERROR)
      end
    end

    context 'with git command failure' do
      before do
        allow(repository).to receive(:gitaly_operation_client).and_raise(Gitlab::Git::Repository::GitError, 'Something went wrong')
      end

      it 'saves a generic error message' do
        subject.execute(merge_request)

        expect(merge_request.reload.merge_error).to eq described_class::REBASE_ERROR
      end

      it 'returns an error' do
        expect(service.execute(merge_request)).to match(status: :error,
                                                        message: described_class::REBASE_ERROR)
      end
    end

    context 'valid params' do
      shared_examples_for 'a service that can execute a successful rebase' do
        before do
          service.execute(merge_request)
        end

        it 'rebases source branch' do
          parent_sha = merge_request.source_project.repository.commit(merge_request.source_branch).parents.first.sha
          target_branch_sha = merge_request.target_project.repository.commit(merge_request.target_branch).sha
          expect(parent_sha).to eq(target_branch_sha)
        end

        it 'records the new SHA on the merge request' do
          head_sha = merge_request.source_project.repository.commit(merge_request.source_branch).sha
          expect(merge_request.reload.rebase_commit_sha).to eq(head_sha)
        end

        it 'logs correct author and committer' do
          head_commit = merge_request.source_project.repository.commit(merge_request.source_branch)

          expect(head_commit.author_email).to eq('dmitriy.zaporozhets@gmail.com')
          expect(head_commit.author_name).to eq('Dmitriy Zaporozhets')
          expect(head_commit.committer_email).to eq(user.email)
          expect(head_commit.committer_name).to eq(user.name)
        end
      end

      context 'when the two_step_rebase feature is enabled' do
        before do
          stub_feature_flags(two_step_rebase: true)
        end

        it_behaves_like 'a service that can execute a successful rebase'
      end

      context 'when the two_step_rebase feature is disabled' do
        before do
          stub_feature_flags(two_step_rebase: false)
        end

        it_behaves_like 'a service that can execute a successful rebase'
      end

      context 'fork' do
        describe 'successful fork rebase' do
          let(:forked_project) do
            fork_project(project, user, repository: true)
          end

          let(:merge_request_from_fork) do
            forked_project.repository.create_file(
              user,
              'new-file-to-target',
              '',
              message: 'Add new file to target',
              branch_name: 'master')

            create(:merge_request,
                  source_branch: 'master', source_project: forked_project,
                  target_branch: 'master', target_project: project)
          end

          it 'rebases source branch' do
            parent_sha = forked_project.repository.commit(merge_request_from_fork.source_branch).parents.first.sha
            target_branch_sha = project.repository.commit(merge_request_from_fork.target_branch).sha
            expect(parent_sha).to eq(target_branch_sha)
          end
        end
      end
    end
  end
end
