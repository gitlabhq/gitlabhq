# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::SquashService do
  include GitHelpers

  let(:service) { described_class.new(project: project, current_user: user, params: { merge_request: merge_request }) }
  let(:user) { project.owner }
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository.raw }
  let(:log_error) { "Failed to squash merge request #{merge_request.to_reference(full: true)}:" }
  let(:squash_dir_path) do
    File.join(Gitlab.config.shared.path, 'tmp/squash', repository.gl_repository, merge_request.id.to_s)
  end

  let(:merge_request_with_one_commit) do
    create(:merge_request,
           source_branch: 'feature', source_project: project,
           target_branch: 'master', target_project: project)
  end

  let(:merge_request_with_only_new_files) do
    create(:merge_request,
           source_branch: 'video', source_project: project,
           target_branch: 'master', target_project: project)
  end

  let(:merge_request_with_large_files) do
    create(:merge_request,
           source_branch: 'squash-large-files', source_project: project,
           target_branch: 'master', target_project: project)
  end

  shared_examples 'the squash succeeds' do
    it 'returns the squashed commit SHA' do
      result = service.execute

      expect(result).to match(status: :success, squash_sha: a_string_matching(/\h{40}/))
      expect(result[:squash_sha]).not_to eq(merge_request.diff_head_sha)
    end

    it 'cleans up the temporary directory' do
      service.execute

      expect(File.exist?(squash_dir_path)).to be(false)
    end

    it 'does not keep the branch push event' do
      expect { service.execute }.not_to change { Event.count }
    end

    context 'when there is a single commit in the merge request' do
      before do
        expect(merge_request).to receive(:commits_count).at_least(:once).and_return(1)
      end

      it 'will skip performing the squash, as the outcome would be the same' do
        expect(merge_request.target_project.repository).not_to receive(:squash)

        service.execute
      end

      it 'will still perform the squash when a custom squash commit message has been provided' do
        service = described_class.new(project: project, current_user: user, params: { merge_request: merge_request, squash_commit_message: 'A custom commit message' })

        expect(merge_request.target_project.repository).to receive(:squash).and_return('sha')

        service.execute
      end
    end

    context 'the squashed commit' do
      let(:squash_sha) { service.execute[:squash_sha] }
      let(:squash_commit) { project.repository.commit(squash_sha) }

      it 'copies the author info from the merge request' do
        expect(squash_commit.author_name).to eq(merge_request.author.name)
        expect(squash_commit.author_email).to eq(merge_request.author.email)
      end

      it 'sets the current user as the committer' do
        expect(squash_commit.committer_name).to eq(user.name.chomp('.'))
        expect(squash_commit.committer_email).to eq(user.email)
      end

      it 'has the same diff as the merge request, but a different SHA' do
        rugged = rugged_repo(project.repository)
        mr_diff = rugged.diff(merge_request.diff_base_sha, merge_request.diff_head_sha)
        squash_diff = rugged.diff(merge_request.diff_start_sha, squash_sha)

        expect(squash_diff.patch.length).to eq(mr_diff.patch.length)
        expect(squash_commit.sha).not_to eq(merge_request.diff_head_sha)
      end

      it 'has a default squash commit message if no message was provided' do
        expect(squash_commit.message.chomp).to eq(merge_request.default_squash_commit_message.chomp)
      end

      context 'if a message was provided' do
        let(:service) { described_class.new(project: project, current_user: user, params: { merge_request: merge_request, squash_commit_message: message }) }
        let(:message) { 'My custom message' }
        let(:squash_sha) { service.execute[:squash_sha] }

        it 'has the same message as the message provided' do
          expect(squash_commit.message.chomp).to eq(message)
        end
      end
    end
  end

  describe '#execute' do
    context 'when there is only one commit in the merge request' do
      let(:merge_request) { merge_request_with_one_commit }

      it 'returns that commit SHA' do
        result = service.execute

        expect(result).to match(status: :success, squash_sha: merge_request.diff_head_sha)
      end

      it 'does not perform any git actions' do
        expect(repository).not_to receive(:popen)

        service.execute
      end
    end

    context 'when squashing only new files' do
      let(:merge_request) { merge_request_with_only_new_files }

      include_examples 'the squash succeeds'
    end

    context 'when squashing is disabled by default on the project' do
      # Squashing is disabled by default, but it should still allow you
      # to squash-and-merge if selected through the UI
      let(:merge_request) { merge_request_with_only_new_files }

      before do
        merge_request.project.project_setting.squash_default_off!
      end

      include_examples 'the squash succeeds'
    end

    context 'when squashing is forbidden on the project' do
      let(:merge_request) { merge_request_with_only_new_files }

      before do
        merge_request.project.project_setting.squash_never!
      end

      it 'raises a squash error' do
        expect(service.execute).to match(
          status: :error,
          message: a_string_including('does not allow squashing commits when merge requests are accepted'))
      end
    end

    context 'when squashing is enabled by default on the project' do
      let(:merge_request) { merge_request_with_only_new_files }

      before do
        merge_request.project.project_setting.squash_always!
      end

      include_examples 'the squash succeeds'
    end

    context 'when squashing with files too large to display' do
      let(:merge_request) { merge_request_with_large_files }

      include_examples 'the squash succeeds'
    end

    context 'git errors' do
      let(:merge_request) { merge_request_with_only_new_files }
      let(:error) { 'A test error' }

      context 'with an error in Gitaly UserSquash RPC' do
        before do
          allow(repository.gitaly_operation_client).to receive(:user_squash)
            .and_raise(Gitlab::Git::Repository::GitError, error)
        end

        it 'logs the error' do
          expect(service).to receive(:log_error).with(exception: an_instance_of(Gitlab::Git::Repository::GitError), message: 'Failed to squash merge request')

          service.execute
        end

        it 'returns an error' do
          expect(service.execute).to match(status: :error, message: a_string_including('squash'))
        end
      end

      context 'with an error in squash in progress check' do
        before do
          allow(repository).to receive(:squash_in_progress?)
            .and_raise(Gitlab::Git::Repository::GitError, error)
        end

        it 'logs the stage and output' do
          expect(service).to receive(:log_error).with(exception: an_instance_of(Gitlab::Git::Repository::GitError), message: 'Failed to check squash in progress')

          service.execute
        end

        it 'returns an error' do
          expect(service.execute).to match(status: :error, message: 'An error occurred while checking whether another squash is in progress.')
        end
      end
    end

    context 'when any other exception is thrown' do
      let(:merge_request) { merge_request_with_only_new_files }
      let(:merge_request_ref) { merge_request.to_reference(full: true) }
      let(:exception) { RuntimeError.new('A test error') }

      before do
        allow(merge_request.target_project.repository).to receive(:squash).and_raise(exception)
      end

      it 'logs the error' do
        expect(service).to receive(:log_error).with(exception: exception, message: 'Failed to squash merge request').and_call_original
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(exception,
          class: described_class.to_s,
          merge_request: merge_request_ref,
          merge_request_id: merge_request.id,
          message: 'Failed to squash merge request',
          save_message_on_model: false).and_call_original

        service.execute
      end

      it 'returns an error' do
        expect(service.execute).to match(status: :error, message: a_string_including('squash'))
      end

      it 'cleans up the temporary directory' do
        service.execute

        expect(File.exist?(squash_dir_path)).to be(false)
      end
    end
  end
end
