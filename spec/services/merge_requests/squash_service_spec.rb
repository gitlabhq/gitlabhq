# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::SquashService, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }

  let(:commit_message) { nil }
  let(:repository) { project.repository.raw }
  let(:service) do
    described_class.new(merge_request: merge_request, current_user: user, commit_message: commit_message)
  end

  let(:squash_dir_path) do
    File.join(Gitlab.config.shared.path, 'tmp/squash', repository.gl_repository, merge_request.id.to_s)
  end

  let_it_be(:merge_request_with_one_commit) do
    create(
      :merge_request,
      source_branch: 'feature', source_project: project,
      target_branch: 'master', target_project: project
    )
  end

  let_it_be(:merge_request_with_only_new_files) do
    create(
      :merge_request,
      source_branch: 'video', source_project: project,
      target_branch: 'master', target_project: project
    )
  end

  let_it_be(:merge_request_with_large_files) do
    create(
      :merge_request,
      source_branch: 'squash-large-files', source_project: project,
      target_branch: 'master', target_project: project
    )
  end

  shared_examples 'the squash succeeds' do
    it 'returns the squashed commit SHA', :aggregate_failures do
      result = service.execute

      expect(result).to match(status: :success, squash_sha: a_string_matching(/\h{40}/))
      expect(result[:squash_sha]).not_to eq(merge_request.diff_head_sha)
      expect(File.exist?(squash_dir_path)).to be(false)
    end

    it 'does not keep the branch push event' do
      expect { service.execute }.not_to change { Event.count }
    end

    context 'when there is a single commit in the merge request' do
      let(:mock_sha) { 'sha' }

      before do
        allow(merge_request).to receive(:commits_count).and_return(1)
        allow(merge_request.target_project.repository).to receive(:squash).and_return(mock_sha)
      end

      subject(:result) { service.execute }

      context 'and the squash message does not match the commit message' do
        it 'squashes the commit' do
          expect(result).to match(status: :success, squash_sha: mock_sha)
        end
      end

      context 'when squash message matches commit message' do
        let(:commit_message) { merge_request.first_commit.safe_message }

        it 'returns that commit SHA', :aggregate_failures do
          expect(result).to match(status: :success, squash_sha: merge_request.diff_head_sha)
          expect(merge_request.target_project.repository).not_to have_received(:squash)
        end
      end

      context 'when squash message matches commit message but without trailing new line' do
        let(:commit_message) { merge_request.first_commit.safe_message.strip }

        it 'returns that commit SHA', :aggregate_failures do
          expect(result).to match(status: :success, squash_sha: merge_request.diff_head_sha)
          expect(merge_request.target_project.repository).not_to have_received(:squash)
        end
      end
    end

    describe 'the squashed commit' do
      let(:squash_sha) { service.execute[:squash_sha] }

      subject(:squash_commit) { project.repository.commit(squash_sha) }

      it 'assigns the correct details to the new commit and has a matching diff', :aggregate_failures do
        expect(squash_commit.author_name).to eq(merge_request.author.name)
        expect(squash_commit.author_email).to eq(merge_request.author.email)

        expect(squash_commit.committer_name).to eq(user.name.chomp('.'))
        expect(squash_commit.committer_email).to eq(user.email)

        expect(squash_commit.message.chomp).to eq(merge_request.default_squash_commit_message.chomp)

        mr_diff = project.repository.diff(merge_request.diff_base_sha, merge_request.diff_head_sha)
        squash_diff = project.repository.diff(merge_request.diff_start_sha, squash_sha)
        expect(squash_diff.size).to eq(mr_diff.size)
        expect(squash_commit.sha).not_to eq(merge_request.diff_head_sha)
      end

      context 'if a message was provided' do
        let(:commit_message) { 'My custom message' }

        it 'has the same message as the message provided' do
          expect(squash_commit.message.chomp).to eq(commit_message)
        end
      end
    end
  end

  shared_examples 'the squash is forbidden' do
    it 'raises a squash error' do
      expect(service.execute).to match(
        status: :error,
        message: "Squashing not allowed: This project doesn't allow you to squash commits when merging."
      )
    end
  end

  describe '#execute' do
    context 'when there is only one commit in the merge request' do
      let(:merge_request) { merge_request_with_one_commit }

      it_behaves_like 'the squash succeeds'
    end

    context 'when squashing only new files' do
      let(:merge_request) { merge_request_with_only_new_files }

      it_behaves_like 'the squash succeeds'
    end

    context 'when squashing is disabled by default on the project' do
      # Squashing is disabled by default, but it should still allow you
      # to squash-and-merge if selected through the UI
      let(:merge_request) { merge_request_with_only_new_files }

      before do
        merge_request.project.project_setting.squash_default_off!
      end

      it_behaves_like 'the squash succeeds'
    end

    context 'when squashing is forbidden on the project' do
      let(:merge_request) { merge_request_with_only_new_files }

      before do
        allow(merge_request.target_project.project_setting).to receive(:squash_never?).and_return(true)
      end

      it_behaves_like 'the squash is forbidden'
    end

    context 'when squashing is enabled by default on the project' do
      let(:merge_request) { merge_request_with_only_new_files }

      before do
        merge_request.project.project_setting.squash_always!
      end

      it_behaves_like 'the squash succeeds'
    end

    context 'when squashing with files too large to display' do
      let(:merge_request) { merge_request_with_large_files }

      it_behaves_like 'the squash succeeds'
    end

    describe 'git errors' do
      let(:merge_request) { merge_request_with_only_new_files }
      let(:error) { 'A test error' }

      context 'with an error in Gitaly UserSquash RPC' do
        before do
          allow(merge_request.target_project.repository.gitaly_operation_client)
            .to receive(:user_squash)
            .and_raise(Gitlab::Git::Repository::GitError, error)
          allow(service).to receive(:log_error)
        end

        it 'logs and returns an error and cleans up the temp dir\cp', :aggregate_failures do
          response = service.execute

          expect(response).to match(
            status: :error,
            message: 'Squashing failed: Squash the commits locally, resolve any conflicts, then push the branch.'
          )

          expect(service).to have_received(:log_error).with(
            exception: an_instance_of(Gitlab::Git::Repository::GitError),
            message: 'Failed to squash merge request'
          )

          expect(File.exist?(squash_dir_path)).to be(false)
        end
      end
    end

    context 'when any other exception is thrown' do
      let(:merge_request) { merge_request_with_only_new_files }
      let(:merge_request_ref) { merge_request.to_reference(full: true) }
      let(:exception) { RuntimeError.new('A test error') }
      let(:error_message) do
        'Squashing failed: Squash the commits locally, resolve any conflicts, then push the branch.'
      end

      let(:message) do
        <<~MSG.chomp
          MergeRequests::SquashService error (#{merge_request.to_reference(full: true)}): Failed to squash merge request
        MSG
      end

      before do
        allow(merge_request.target_project.repository).to receive(:squash).and_raise(exception)
        allow(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original
      end

      it 'logs and returns an error and cleans up the temp dir' do
        expect(service.execute).to match(status: :error, message: error_message)

        expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
          exception,
          {
            'exception.message': exception.message,
            class: described_class.to_s,
            merge_request: merge_request_ref,
            merge_request_id: merge_request.id,
            message: message,
            save_message_on_model: false
          }
        )

        expect(File.exist?(squash_dir_path)).to be(false)
      end
    end
  end
end
