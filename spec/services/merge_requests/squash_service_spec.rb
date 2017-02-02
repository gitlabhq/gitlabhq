require 'spec_helper'

describe MergeRequests::SquashService do
  let(:service) { described_class.new(project, user, {}) }
  let(:user) { project.owner }
  let(:project) { create(:project) }

  let(:merge_request) do
    create(:merge_request,
           source_branch: 'fix', source_project: project,
           target_branch: 'master', target_project: project)
  end

  let(:merge_request_with_one_commit) do
    create(:merge_request,
           source_branch: 'feature.custom-highlighting', source_project: project,
           target_branch: 'master', target_project: project)
  end

  def git_command(command)
    a_collection_starting_with([Gitlab.config.git.bin_path, command])
  end

  shared_examples 'the squashed commit' do
  end

  describe '#execute' do
    context 'when there is only one commit in the merge request' do
      it 'returns that commit SHA' do
        result = service.execute(merge_request_with_one_commit)

        expect(result).to match(status: :success, squash_sha: merge_request_with_one_commit.diff_head_sha)
      end

      it 'does not perform any git actions' do
        expect(service).not_to receive(:run_git_command)

        service.execute(merge_request_with_one_commit)
      end
    end

    context 'when the squash succeeds' do
      it 'returns the squashed commit SHA' do
        result = service.execute(merge_request)

        expect(result).to match(status: :success, squash_sha: a_string_matching(/\h{40}/))
        expect(result[:squash_sha]).not_to eq(merge_request.diff_head_sha)
      end

      it 'cleans up the temporary directory' do
        expect(service).to receive(:clean_dir).and_call_original

        service.execute(merge_request)
      end

      it 'does not keep the branch push event' do
        expect { service.execute(merge_request) }.not_to change { Event.count }
      end

      context 'the squashed commit' do
        let(:squash_sha) { service.execute(merge_request)[:squash_sha] }
        let(:squash_commit) { project.repository.commit(squash_sha) }

        it 'copies the author info and message from the last commit in the source branch' do
          diff_head_commit = merge_request.diff_head_commit

          expect(squash_commit.author_name).to eq(diff_head_commit.author_name)
          expect(squash_commit.author_email).to eq(diff_head_commit.author_email)
          expect(squash_commit.message).to eq(diff_head_commit.message)
        end

        it 'sets the current user as the committer' do
          expect(squash_commit.committer_name).to eq(user.name.chomp('.'))
          expect(squash_commit.committer_email).to eq(user.email)
        end

        it 'has the same diff as the merge request, but a different SHA' do
          rugged = project.repository.rugged
          mr_diff = rugged.diff(merge_request.diff_base_sha, merge_request.diff_head_sha)
          squash_diff = rugged.diff(merge_request.diff_start_sha, squash_sha)

          expect(squash_diff.patch).to eq(mr_diff.patch)
          expect(squash_commit.sha).not_to eq(merge_request.diff_head_sha)
        end
      end
    end

    stages = {
      'add worktree for squash' => 'worktree',
      'apply patch' => 'apply',
      'commit squashed changes' => 'commit',
      'get SHA of squashed commit' => 'rev-parse'
    }

    stages.each do |stage, command|
      context "when the #{stage} stage fails" do
        let(:error) { 'A test error' }

        before do
          allow(service).to receive(:popen).and_return(['', 0])
          allow(service).to receive(:popen).with(git_command(command), anything, anything).and_return([error, 1])
        end

        it 'logs the stage and output' do
          expect(service).to receive(:log_error).with(a_string_including(stage))
          expect(service).to receive(:log_error).with(error)

          service.execute(merge_request)
        end

        it 'returns an error' do
          expect(service.execute(merge_request)).to match(status: :error,
                                                          message: a_string_including('squash'))
        end

        it 'cleans up the temporary directory' do
          expect(service).to receive(:clean_dir).and_call_original

          service.execute(merge_request)
        end
      end
    end

    context 'when any other exception is thrown' do
      let(:error) { 'A test error' }

      before do
        allow(merge_request).to receive(:commits_count).and_raise(error)
      end

      it 'logs the MR reference and exception' do
        expect(service).to receive(:log_error).with(a_string_including("#{project.path_with_namespace}#{merge_request.to_reference}"))
        expect(service).to receive(:log_error).with(error)

        service.execute(merge_request)
      end

      it 'returns an error' do
        expect(service.execute(merge_request)).to match(status: :error,
                                                        message: a_string_including('squash'))
      end

      it 'cleans up the temporary directory' do
        expect(service).to receive(:clean_dir).and_call_original

        service.execute(merge_request)
      end
    end
  end
end
