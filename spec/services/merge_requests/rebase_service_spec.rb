# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RebaseService, feature_category: :source_code_management do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:rebase_jid) { 'fake-rebase-jid' }
  let(:merge_request) do
    create(
      :merge_request,
      source_branch: 'feature_conflict',
      target_branch: 'master',
      rebase_jid: rebase_jid
    )
  end

  let(:project) { merge_request.project }
  let(:repository) { project.repository.raw }
  let(:skip_ci) { false }

  subject(:service) { described_class.new(project: project, current_user: user) }

  before do
    project.add_maintainer(user)
  end

  describe '#validate' do
    subject { service.validate(merge_request) }

    it { is_expected.to be_success }

    context 'when source branch does not exist' do
      before do
        merge_request.update!(source_branch: 'does_not_exist')
      end

      it 'returns an error' do
        is_expected.to be_error
        expect(subject.message).to eq('Source branch does not exist')
      end
    end

    context 'when user has no permissions to rebase' do
      before do
        project.add_guest(user)
      end

      it 'returns an error' do
        is_expected.to be_error
        expect(subject.message).to eq('Cannot push to source branch')
      end
    end

    context 'when branch is protected' do
      before do
        create(:protected_branch, project: project, name: merge_request.source_branch, allow_force_push: false)
      end

      it 'returns an error' do
        is_expected.to be_error
        expect(subject.message).to eq('Source branch is protected from force push')
      end
    end
  end

  describe '#execute' do
    shared_examples 'sequence of failure and success' do
      it 'properly clears the error message' do
        allow(repository).to receive(:gitaly_operation_client).and_raise('Something went wrong')

        service.execute(merge_request)
        merge_request.reload

        expect(merge_request.reload.merge_error).to eq(described_class::REBASE_ERROR)
        expect(merge_request.rebase_jid).to eq(nil)

        allow(repository).to receive(:gitaly_operation_client).and_call_original
        merge_request.update!(rebase_jid: rebase_jid)

        service.execute(merge_request)
        merge_request.reload

        expect(merge_request.merge_error).to eq(nil)
        expect(merge_request.rebase_jid).to eq(nil)
      end
    end

    it_behaves_like 'sequence of failure and success'

    context 'when unexpected error occurs' do
      let(:exception) { RuntimeError.new('Something went wrong') }
      let(:merge_request_ref) { merge_request.to_reference(full: true) }

      before do
        allow(repository).to receive(:gitaly_operation_client).and_raise(exception)
      end

      it 'saves a generic error message' do
        service.execute(merge_request)

        expect(merge_request.reload.merge_error).to eq(described_class::REBASE_ERROR)
      end

      it 'returns an error' do
        expect(service.execute(merge_request)).to match(
          status: :error, message: described_class::REBASE_ERROR
        )
      end

      it 'logs the error' do
        expect(service).to receive(:log_error).with(exception: exception, message: described_class::REBASE_ERROR, save_message_on_model: true).and_call_original
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(exception,
          {
            class: described_class.to_s,
            merge_request: merge_request_ref,
            merge_request_id: merge_request.id,
            message: described_class::REBASE_ERROR,
            save_message_on_model: true
          }).and_call_original

        service.execute(merge_request)
      end
    end

    context 'with a pre-receive failure' do
      let(:pre_receive_error) { "Commit message does not follow the pattern 'ACME'" }
      let(:merge_error) { "The rebase pre-receive hook failed: #{pre_receive_error}." }

      before do
        allow(repository).to receive(:gitaly_operation_client).and_raise(Gitlab::Git::PreReceiveError, "GitLab: #{pre_receive_error}")
      end

      it 'saves a specific message' do
        subject.execute(merge_request)

        expect(merge_request.reload.merge_error).to eq merge_error
      end

      it 'returns an error' do
        expect(service.execute(merge_request)).to match(
          status: :error,
          message: merge_error)
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
        expect(service.execute(merge_request)).to match(
          status: :error, message: described_class::REBASE_ERROR
        )
      end
    end

    context 'valid params' do
      shared_examples_for 'a service that can execute a successful rebase' do
        before do
          service.execute(merge_request, skip_ci: skip_ci)
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

      it_behaves_like 'a service that can execute a successful rebase'

      it 'clears rebase_jid' do
        expect { service.execute(merge_request) }
          .to change(merge_request, :rebase_jid)
          .from(rebase_jid)
          .to(nil)
      end

      context 'when skip_ci flag is set' do
        let(:skip_ci) { true }

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

            create(
              :merge_request,
              source_branch: 'master', source_project: forked_project,
              target_branch: 'master', target_project: project
            )
          end

          it 'rebases source branch', :sidekiq_might_not_need_inline do
            parent_sha = forked_project.repository.commit(merge_request_from_fork.source_branch).parents.first.sha
            target_branch_sha = project.repository.commit(merge_request_from_fork.target_branch).sha
            expect(parent_sha).to eq(target_branch_sha)
          end
        end
      end
    end
  end
end
