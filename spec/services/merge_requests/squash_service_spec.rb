require 'spec_helper'

describe MergeRequests::SquashService do
  let(:service) { described_class.new(project, user, {}) }
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, source_branch: 'feature_conflict', target_branch: 'master') }
  let(:project) { merge_request.project }

  before do
    project.team << [user, :master]
  end

  describe '#execute' do
    context 'when the squash succeeds' do
      it 'returns the squashed commit SHA' do
        expect(service.execute(merge_request)).to match(status: :success,
                                                        squash_sha: a_string_matching(/\h{40}/))
      end

      it 'cleans up the temporary directory' do
        expect(service).to receive(:clean_dir).and_call_original

        service.execute(merge_request)
      end

      context 'the squashed commit' do
        let(:squashed_commit) do
          squash_oid = service.execute(merge_request)[:squash_sha]

          project.repository.commit(squash_oid)
        end

        it 'copies the author info and message from the last commit in the source branch' do
          diff_head_commit = merge_request.diff_head_commit

          expect(squashed_commit.author_name).to eq(diff_head_commit.author_name)
          expect(squashed_commit.author_email).to eq(diff_head_commit.author_email)
          expect(squashed_commit.message).to eq(diff_head_commit.message)
        end

        it 'sets the current user as the committer' do
          expect(squashed_commit.committer_name).to eq(user.name)
          expect(squashed_commit.committer_email).to eq(user.email)
        end
      end
    end

    stages = {
      'clone repository' => 'clone',
      'apply patch' => 'apply',
      'commit squashed changes' => 'commit',
      'get SHA of squashed branch' => 'rev-parse',
      'push squashed branch' => 'push'
    }

    stages.each do |stage, command|
      context "when the #{stage} stage fails" do
        let(:error) { 'A test error' }

        before do
          git_command = a_collection_starting_with([Gitlab.config.git.bin_path, command])

          allow(service).to receive(:popen).and_return(['', 0])

          allow(service).to receive(:popen).with(git_command, anything, anything) do
            [error, 1]
          end
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
        allow(SecureRandom).to receive(:uuid).and_raise(error)
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
