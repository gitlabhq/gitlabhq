# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::OperationService, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:repository) { project.repository.raw }
  let(:client) { described_class.new(repository) }
  let(:gitaly_user) { Gitlab::Git::User.from_gitlab(user).to_gitaly }

  describe '#user_create_branch' do
    let(:branch_name) { 'new' }
    let(:start_point) { 'master' }
    let(:request) do
      Gitaly::UserCreateBranchRequest.new(
        repository: repository.gitaly_repository,
        branch_name: branch_name,
        start_point: start_point,
        user: gitaly_user
      )
    end

    let(:gitaly_commit) { build(:gitaly_commit) }
    let(:commit_id) { gitaly_commit.id }
    let(:gitaly_branch) do
      Gitaly::Branch.new(name: branch_name, target_commit: gitaly_commit)
    end

    let(:response) { Gitaly::UserCreateBranchResponse.new(branch: gitaly_branch) }
    let(:commit) { Gitlab::Git::Commit.new(repository, gitaly_commit) }

    subject { client.user_create_branch(branch_name, user, start_point) }

    it 'sends a user_create_branch message and returns a Gitlab::git::Branch' do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_create_branch).with(request, kind_of(Hash))
        .and_return(response)

      expect(subject.name).to eq(branch_name)
      expect(subject.dereferenced_target).to eq(commit)
    end

    context 'with structured errors' do
      context 'with CustomHookError' do
        let(:stdout) { nil }
        let(:stderr) { nil }
        let(:error_message) { "error_message" }

        let(:custom_hook_error) do
          new_detailed_error(
            GRPC::Core::StatusCodes::PERMISSION_DENIED,
            error_message,
            Gitaly::UserCreateBranchError.new(
              custom_hook: Gitaly::CustomHookError.new(
                stdout: stdout,
                stderr: stderr,
                hook_type: Gitaly::CustomHookError::HookType::HOOK_TYPE_PRERECEIVE
              )))
        end

        shared_examples 'failed branch creation' do
          it 'raised a PreRecieveError' do
            expect_any_instance_of(Gitaly::OperationService::Stub)
              .to receive(:user_create_branch)
              .and_raise(custom_hook_error)

            expect { subject }.to raise_error do |error|
              expect(error).to be_a(Gitlab::Git::PreReceiveError)
              expect(error.message).to eq(expected_message)
              expect(error.raw_message).to eq(expected_raw_message)
            end
          end
        end

        context 'when details contain stderr without prefix' do
          let(:stderr) { "something" }
          let(:stdout) { "GL-HOOK-ERR: stdout is overridden by stderr" }
          let(:expected_message) { Gitlab::GitalyClient::OperationService::CUSTOM_HOOK_FALLBACK_MESSAGE }
          let(:expected_raw_message) { stderr }

          it_behaves_like 'failed branch creation'
        end

        context 'when details contain stderr with prefix' do
          let(:stderr) { "GL-HOOK-ERR: something" }
          let(:stdout) { "GL-HOOK-ERR: stdout is overridden by stderr" }
          let(:expected_message) { "something" }
          let(:expected_raw_message) { stderr }

          it_behaves_like 'failed branch creation'
        end

        context 'when details contain stdout without prefix' do
          let(:stderr) { "      \n" }
          let(:stdout) { "something" }
          let(:expected_message) { Gitlab::GitalyClient::OperationService::CUSTOM_HOOK_FALLBACK_MESSAGE }
          let(:expected_raw_message) { stdout }

          it_behaves_like 'failed branch creation'
        end

        context 'when details contain stdout with prefix' do
          let(:stderr) { "      \n" }
          let(:stdout) { "GL-HOOK-ERR: something" }
          let(:expected_message) { "something" }
          let(:expected_raw_message) { stdout }

          it_behaves_like 'failed branch creation'
        end

        context 'when details contain no stderr or stdout' do
          let(:stderr) { "      \n" }
          let(:stdout) { "\n    \n" }
          let(:expected_message) { Gitlab::GitalyClient::OperationService::CUSTOM_HOOK_FALLBACK_MESSAGE }
          let(:expected_raw_message) { "\n    \n" }

          it_behaves_like 'failed branch creation'
        end
      end
    end
  end

  describe '#user_update_branch' do
    let(:branch_name) { 'my-branch' }
    let(:newrev) { '01e' }
    let(:oldrev) { '01d' }
    let(:request) do
      Gitaly::UserUpdateBranchRequest.new(
        repository: repository.gitaly_repository,
        branch_name: branch_name,
        newrev: newrev,
        oldrev: oldrev,
        user: gitaly_user
      )
    end

    let(:response) { Gitaly::UserUpdateBranchResponse.new }

    subject { client.user_update_branch(branch_name, user, newrev, oldrev) }

    it 'sends a user_update_branch message' do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_update_branch).with(request, kind_of(Hash))
        .and_return(response)

      subject
    end

    context "when pre_receive_error is present" do
      let(:response) do
        Gitaly::UserUpdateBranchResponse.new(pre_receive_error: "GitLab: something failed")
      end

      it "throws a PreReceive exception" do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_update_branch).with(request, kind_of(Hash))
          .and_return(response)

        expect { subject }.to raise_error(
          Gitlab::Git::PreReceiveError, "something failed")
      end
    end
  end

  describe '#user_merge_to_ref' do
    let(:first_parent_ref) { 'refs/heads/my-branch' }
    let(:source_sha) { 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660' }
    let(:ref) { 'refs/merge-requests/x/merge' }
    let(:message) { 'validación' }
    let(:response) { Gitaly::UserMergeToRefResponse.new(commit_id: 'new-commit-id') }

    let(:payload) do
      { source_sha: source_sha, branch: 'branch', target_ref: ref,
        message: message, first_parent_ref: first_parent_ref }
    end

    it 'sends a user_merge_to_ref message' do
      freeze_time do
        expect_any_instance_of(Gitaly::OperationService::Stub).to receive(:user_merge_to_ref) do |_, request, options|
          expect(options).to be_kind_of(Hash)
          expect(request.to_h).to eq(
            payload.merge({
              allow_conflicts: false,
              expected_old_oid: "",
              repository: repository.gitaly_repository.to_h,
              message: message.dup.force_encoding(Encoding::ASCII_8BIT),
              user: Gitlab::Git::User.from_gitlab(user).to_gitaly.to_h,
              timestamp: { nanos: 0, seconds: Time.current.to_i }
            })
          )
        end.and_return(response)

        client.user_merge_to_ref(user, **payload)
      end
    end
  end

  describe '#user_delete_branch' do
    let(:branch_name) { 'my-branch' }
    let(:start_point) { 'master' }
    let(:target_sha) { 'sha_for_branch_name' }
    let(:request) do
      Gitaly::UserDeleteBranchRequest.new(
        repository: repository.gitaly_repository,
        branch_name: branch_name,
        user: gitaly_user,
        expected_old_oid: target_sha
      )
    end

    let(:response) { Gitaly::UserDeleteBranchResponse.new }

    subject { client.user_delete_branch(branch_name, user, target_sha: target_sha) }

    it 'sends a user_delete_branch message' do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_delete_branch).with(request, kind_of(Hash))
        .and_return(response)

      subject
    end

    context 'when target_sha is not provided' do
      let(:target_sha) { nil }

      it 'sends a user_delete_branch message without target_sha' do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_delete_branch).with(request, kind_of(Hash))
          .and_return(response)

        subject
      end
    end

    context 'with an invalid target_sha' do
      let(:target_sha) { 'invalid-target-sha' }

      it 'raises a CommandError' do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_delete_branch).with(request, kind_of(Hash))
          .and_raise(GRPC::InvalidArgument.new('Invalid argument'))

        expect { subject }.to raise_error(Gitlab::Git::CommandError)
      end
    end

    context 'with a custom hook error' do
      let(:stdout) { nil }
      let(:stderr) { nil }
      let(:error_message) { "error_message" }
      let(:custom_hook_error) do
        new_detailed_error(
          GRPC::Core::StatusCodes::PERMISSION_DENIED,
          error_message,
          Gitaly::UserDeleteBranchError.new(
            custom_hook: Gitaly::CustomHookError.new(
              stdout: stdout,
              stderr: stderr,
              hook_type: Gitaly::CustomHookError::HookType::HOOK_TYPE_PRERECEIVE
            )))
      end

      shared_examples 'a failed branch deletion' do
        it 'raises a PreReceiveError' do
          expect_any_instance_of(Gitaly::OperationService::Stub)
            .to receive(:user_delete_branch).with(request, kind_of(Hash))
            .and_raise(custom_hook_error)

          expect { subject }.to raise_error do |error|
            expect(error).to be_a(Gitlab::Git::PreReceiveError)
            expect(error.message).to eq(expected_message)
            expect(error.raw_message).to eq(expected_raw_message)
          end
        end
      end

      context 'when details contain stderr' do
        let(:stderr) { "something" }
        let(:stdout) { "GL-HOOK-ERR: stdout is overridden by stderr" }
        let(:expected_message) { Gitlab::GitalyClient::OperationService::CUSTOM_HOOK_FALLBACK_MESSAGE }
        let(:expected_raw_message) { stderr }

        it_behaves_like 'a failed branch deletion'
      end

      context 'when details contain stdout' do
        let(:stderr) { "      \n" }
        let(:stdout) { "something" }
        let(:expected_message) { Gitlab::GitalyClient::OperationService::CUSTOM_HOOK_FALLBACK_MESSAGE }
        let(:expected_raw_message) { stdout }

        it_behaves_like 'a failed branch deletion'
      end
    end

    context 'with a non-detailed error' do
      it 'raises a GRPC error' do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_delete_branch).with(request, kind_of(Hash))
          .and_raise(GRPC::Internal.new('non-detailed error'))

        expect { subject }.to raise_error(GRPC::Internal)
      end
    end
  end

  describe '#user_merge_branch' do
    let(:target_branch) { 'master' }
    let(:target_sha) { repository.commit(target_branch).sha }
    let(:source_sha) { '5937ac0a7beb003549fc5fd26fc247adbce4a52e' }
    let(:message) { 'Merge a branch' }

    subject do
      client.user_merge_branch(user,
        source_sha: source_sha,
        target_branch: target_branch,
        target_sha: target_sha,
        message: message
      ) {}
    end

    it 'succeeds' do
      expect(subject).to be_a(Gitlab::Git::OperationService::BranchUpdate)
      expect(subject.newrev).to be_present
      expect(subject.repo_created).to be(false)
      expect(subject.branch_created).to be(false)
    end

    it 'receives a bad status' do
      expect(client).to receive(:gitaly_client_call)
        .and_wrap_original { |original, *args, **kwargs|
          response_enum = original.call(*args, **kwargs)
          Enumerator.new do |y|
            y << response_enum.next
            y << response_enum.next
            raise 'bad status'
          end
        }

      expect { subject }.to raise_error(RuntimeError, 'bad status')
    end

    it 'receives an unexpected response' do
      expect(client).to receive(:gitaly_client_call)
        .and_wrap_original { |original, *args, **kwargs|
          response_enum = original.call(*args, **kwargs)
          Enumerator.new do |y|
            y << response_enum.next
            y << response_enum.next
            y << 'unexpected response'
          end
        }

      expect { subject }.to raise_error(RuntimeError, 'expected response stream to finish')
    end

    context 'with an exception with the UserMergeBranchError' do
      let(:permission_error) do
        new_detailed_error(
          GRPC::Core::StatusCodes::PERMISSION_DENIED,
          "GitLab: You are not allowed to push code to this project.",
          Gitaly::UserMergeBranchError.new(
            access_check: Gitaly::AccessCheckError.new(
              error_message: "You are not allowed to push code to this project.",
              protocol: "web",
              user_id: "user-15",
              changes: "df15b32277d2c55c6c595845a87109b09c913c556 5d6e0f935ad9240655f64e883cd98fad6f9a17ee refs/heads/master\n"
            )))
      end

      it 'raises PreRecieveError with the error message' do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_merge_branch).with(kind_of(Enumerator), kind_of(Hash))
          .and_raise(permission_error)

        expect { subject }.to raise_error do |error|
          expect(error).to be_a(Gitlab::Git::PreReceiveError)
          expect(error.message).to eq("You are not allowed to push code to this project.")
        end
      end
    end

    context 'with a custom hook error' do
      let(:stdout) { nil }
      let(:stderr) { nil }
      let(:error_message) { "error_message" }
      let(:custom_hook_error) do
        new_detailed_error(
          GRPC::Core::StatusCodes::PERMISSION_DENIED,
          error_message,
          Gitaly::UserMergeBranchError.new(
            custom_hook: Gitaly::CustomHookError.new(
              stdout: stdout,
              stderr: stderr,
              hook_type: Gitaly::CustomHookError::HookType::HOOK_TYPE_PRERECEIVE
            )))
      end

      shared_examples 'a failed merge' do
        it 'raises a PreReceiveError' do
          expect_any_instance_of(Gitaly::OperationService::Stub)
            .to receive(:user_merge_branch).with(kind_of(Enumerator), kind_of(Hash))
            .and_raise(custom_hook_error)

          expect { subject }.to raise_error do |error|
            expect(error).to be_a(Gitlab::Git::PreReceiveError)
            expect(error.message).to eq(expected_message)
            expect(error.raw_message).to eq(expected_raw_message)
          end
        end
      end

      context 'when details contain stderr without prefix' do
        let(:stderr) { "something" }
        let(:stdout) { "GL-HOOK-ERR: stdout is overridden by stderr" }
        let(:expected_message) { Gitlab::GitalyClient::OperationService::CUSTOM_HOOK_FALLBACK_MESSAGE }
        let(:expected_raw_message) { stderr }

        it_behaves_like 'a failed merge'
      end

      context 'when details contain stderr with prefix' do
        let(:stderr) { "GL-HOOK-ERR: something" }
        let(:stdout) { "GL-HOOK-ERR: stdout is overridden by stderr" }
        let(:expected_message) { "something" }
        let(:expected_raw_message) { stderr }

        it_behaves_like 'a failed merge'
      end

      context 'when details contain stdout without prefix' do
        let(:stderr) { "      \n" }
        let(:stdout) { "something" }
        let(:expected_message) { Gitlab::GitalyClient::OperationService::CUSTOM_HOOK_FALLBACK_MESSAGE }
        let(:expected_raw_message) { stdout }

        it_behaves_like 'a failed merge'
      end

      context 'when details contain stdout with prefix' do
        let(:stderr) { "      \n" }
        let(:stdout) { "GL-HOOK-ERR: something" }
        let(:expected_message) { "something" }
        let(:expected_raw_message) { stdout }

        it_behaves_like 'a failed merge'
      end

      context 'when details contain no stderr or stdout' do
        let(:stderr) { "      \n" }
        let(:stdout) { "\n    \n" }
        let(:expected_message) { Gitlab::GitalyClient::OperationService::CUSTOM_HOOK_FALLBACK_MESSAGE }
        let(:expected_raw_message) { "\n    \n" }

        it_behaves_like 'a failed merge'
      end
    end

    context 'with an exception without the detailed error' do
      let(:permission_error) do
        GRPC::PermissionDenied.new
      end

      it 'raises PermissionDenied' do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_merge_branch).with(kind_of(Enumerator), kind_of(Hash))
          .and_raise(permission_error)

        expect { subject }.to raise_error(GRPC::PermissionDenied)
      end
    end

    context 'with ReferenceUpdateError' do
      let(:reference_update_error) do
        new_detailed_error(GRPC::Core::StatusCodes::FAILED_PRECONDITION,
          "some ignored error message",
          Gitaly::UserMergeBranchError.new(
            reference_update: Gitaly::ReferenceUpdateError.new(
              reference_name: "refs/heads/something",
              old_oid: "1234",
              new_oid: "6789"
            )))
      end

      it 'returns nil' do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_merge_branch).with(kind_of(Enumerator), kind_of(Hash))
          .and_raise(reference_update_error)

        expect(subject).to be_nil
      end
    end
  end

  describe '#user_ff_branch' do
    let(:target_branch) { 'my-branch' }
    let(:target_sha) { '6d394385cf567f80a8fd85055db1ab4c5295806f' }
    let(:source_sha) { 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660' }
    let(:request) do
      Gitaly::UserFFBranchRequest.new(
        repository: repository.gitaly_repository,
        branch: target_branch,
        commit_id: source_sha,
        expected_old_oid: target_sha,
        user: gitaly_user
      )
    end

    let(:branch_update) do
      Gitaly::OperationBranchUpdate.new(
        commit_id: source_sha,
        repo_created: false,
        branch_created: false
      )
    end

    let(:response) { Gitaly::UserFFBranchResponse.new(branch_update: branch_update) }

    subject do
      client.user_ff_branch(user,
        source_sha: source_sha,
        target_branch: target_branch,
        target_sha: target_sha
      )
    end

    context 'with response' do
      before do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_ff_branch).with(request, kind_of(Hash))
          .and_return(response)
      end

      it 'sends a user_ff_branch message and returns a BranchUpdate object' do
        expect(subject).to be_a(Gitlab::Git::OperationService::BranchUpdate)
        expect(subject.newrev).to eq(source_sha)
        expect(subject.repo_created).to be(false)
        expect(subject.branch_created).to be(false)
      end

      context 'when the response has no branch_update' do
        let(:response) { Gitaly::UserFFBranchResponse.new }

        it { expect(subject).to be_nil }
      end

      context "when the pre-receive hook fails" do
        let(:response) do
          Gitaly::UserFFBranchResponse.new(
            branch_update: nil,
            pre_receive_error: "pre-receive hook error message\n"
          )
        end

        it "raises the error" do
          # the PreReceiveError class strips the GL-HOOK-ERR prefix from this error
          expect { subject }.to raise_error(Gitlab::Git::PreReceiveError, "pre-receive hook failed.")
        end
      end
    end

    context 'with exception' do
      before do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_ff_branch).with(request, kind_of(Hash))
          .and_raise(exception)
      end

      context 'with CustomHookError' do
        let(:exception) do
          new_detailed_error(
            GRPC::Core::StatusCodes::PERMISSION_DENIED,
            "custom hook error",
            Gitaly::UserFFBranchError.new(
              custom_hook: Gitaly::CustomHookError.new(
                stdout: "some stdout",
                stderr: "GitLab: some custom hook error message",
                hook_type: Gitaly::CustomHookError::HookType::HOOK_TYPE_PRERECEIVE
              )))
        end

        it 'raises a PreReceiveError' do
          expect { subject }.to raise_error do |error|
            expect(error).to be_a(Gitlab::Git::PreReceiveError)
            expect(error.message).to eq("some custom hook error message")
          end
        end
      end

      context 'with ReferenceUpdateError' do
        let(:exception) do
          new_detailed_error(GRPC::Core::StatusCodes::FAILED_PRECONDITION,
            "some ignored error message",
            Gitaly::UserFFBranchError.new(reference_update: Gitaly::ReferenceUpdateError.new))
        end

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'with FailedPrecondition' do
        let(:exception) do
          GRPC::FailedPrecondition.new('failed precondition error')
        end

        it 'returns CommitError' do
          expect { subject }.to raise_error(Gitlab::Git::CommitError, exception.message)
        end
      end

      context 'with a bad status' do
        let(:exception) do
          GRPC::Internal.new('internal error')
        end

        it 'raises the exception' do
          expect { subject }.to raise_error(GRPC::Internal, exception.message)
        end
      end

      context 'with unhandled exception' do
        let(:exception) do
          RuntimeError.new('unhandled exception')
        end

        it 'raises the exception' do
          expect { subject }.to raise_error(RuntimeError, exception.message)
        end
      end
    end
  end

  shared_examples 'cherry pick and revert errors' do
    context 'when a pre_receive_error is present' do
      let(:response) { response_class.new(pre_receive_error: "GitLab: something failed") }

      it 'raises a PreReceiveError' do
        expect { subject }.to raise_error(Gitlab::Git::PreReceiveError, "something failed")
      end
    end

    context 'when a commit_error is present' do
      let(:response) { response_class.new(commit_error: "something failed") }

      it 'raises a CommitError' do
        expect { subject }.to raise_error(Gitlab::Git::CommitError, "something failed")
      end
    end

    context 'when a create_tree_error is present' do
      let(:response) { response_class.new(create_tree_error: "something failed", create_tree_error_code: 'EMPTY') }

      it 'raises a CreateTreeError' do
        expect { subject }.to raise_error(Gitlab::Git::Repository::CreateTreeError) do |error|
          expect(error.error_code).to eq(:empty)
        end
      end
    end

    context 'when branch_update is nil' do
      let(:response) { response_class.new }

      it { expect(subject).to be_nil }
    end
  end

  shared_examples '#user_cherry_pick with a gRPC error' do
    it 'raises an exception' do
      expect_any_instance_of(Gitaly::OperationService::Stub).to receive(:user_cherry_pick)
        .and_raise(raised_error)

      expect { subject }.to raise_error(expected_error, expected_error_message)
    end
  end

  describe '#user_cherry_pick', :freeze_time do
    let(:response_class) { Gitaly::UserCherryPickResponse }
    let(:sha) { '54cec5282aa9f21856362fe321c800c236a61615' }
    let(:branch_name) { 'master' }
    let(:cherry_pick_message) { 'Cherry-pick message' }
    let(:time) { Time.now.utc }
    let(:author_name) { user.name }
    let(:author_email) { user.email }
    let(:dry_run) { false }

    let(:branch_update) do
      Gitaly::OperationBranchUpdate.new(
        commit_id: sha,
        repo_created: false,
        branch_created: false
      )
    end

    let(:request) do
      Gitaly::UserCherryPickRequest.new(
        repository: repository.gitaly_repository,
        user: gitaly_user,
        commit: repository.commit.to_gitaly_commit,
        branch_name: branch_name,
        start_branch_name: branch_name,
        start_repository: repository.gitaly_repository,
        message: cherry_pick_message,
        commit_author_name: author_name,
        commit_author_email: author_email,
        timestamp: Google::Protobuf::Timestamp.new(seconds: time.to_i),
        dry_run: dry_run,
        expected_old_oid: target_sha
      )
    end

    let(:target_sha) { repository.find_branch(branch_name).dereferenced_target.id }
    let(:response) { Gitaly::UserCherryPickResponse.new(branch_update: branch_update) }

    subject do
      client.user_cherry_pick(
        user: user,
        commit: repository.commit,
        branch_name: branch_name,
        message: cherry_pick_message,
        start_branch_name: branch_name,
        start_repository: repository,
        author_name: author_name,
        author_email: author_email,
        dry_run: dry_run,
        target_sha: target_sha
      )
    end

    it 'sends a user_cherry_pick message and returns a BranchUpdate' do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_cherry_pick).with(request, kind_of(Hash))
                                      .and_return(response)

      expect(subject).to be_a(Gitlab::Git::OperationService::BranchUpdate)
      expect(subject.newrev).to be_present
      expect(subject.repo_created).to be(false)
      expect(subject.branch_created).to be(false)
    end

    context 'when AccessCheckError is raised' do
      let(:raised_error) do
        new_detailed_error(
          GRPC::Core::StatusCodes::INTERNAL,
          'something failed',
          Gitaly::UserCherryPickError.new(
            access_check: Gitaly::AccessCheckError.new(
              error_message: 'something went wrong'
            )))
      end

      let(:expected_error) { Gitlab::Git::PreReceiveError }
      let(:expected_error_message) { "something went wrong" }

      it_behaves_like '#user_cherry_pick with a gRPC error'
    end

    context 'when NotAncestorError is raised' do
      let(:raised_error) do
        new_detailed_error(
          GRPC::Core::StatusCodes::FAILED_PRECONDITION,
          'Branch diverged',
          Gitaly::UserCherryPickError.new(
            target_branch_diverged: Gitaly::NotAncestorError.new
          )
        )
      end

      let(:expected_error) { Gitlab::Git::CommitError }
      let(:expected_error_message) { 'branch diverged' }

      it_behaves_like '#user_cherry_pick with a gRPC error'
    end

    context 'when MergeConflictError is raised' do
      let(:raised_error) do
        new_detailed_error(
          GRPC::Core::StatusCodes::FAILED_PRECONDITION,
          'Conflict',
          Gitaly::UserCherryPickError.new(
            cherry_pick_conflict: Gitaly::MergeConflictError.new
          )
        )
      end

      let(:expected_error) { Gitlab::Git::Repository::CreateTreeError }
      let(:expected_error_message) {}

      it_behaves_like '#user_cherry_pick with a gRPC error'
    end

    context 'when InvalidArgument is raised' do
      let(:raised_error) { GRPC::InvalidArgument.new('Invalid argument') }
      let(:expected_error) { Gitlab::Git::CommandError }
      let(:expected_error_message) { '3:Invalid argument' }

      it_behaves_like '#user_cherry_pick with a gRPC error'
    end

    context 'when a non-detailed gRPC error is raised' do
      let(:raised_error) { GRPC::Internal.new('non-detailed error') }
      let(:expected_error) { GRPC::Internal }
      let(:expected_error_message) {}

      it_behaves_like '#user_cherry_pick with a gRPC error'
    end
  end

  shared_examples '#user_revert with a gRPC error' do
    it 'raises an exception' do
      expect_any_instance_of(Gitaly::OperationService::Stub).to receive(:user_revert)
        .and_raise(raised_error)

      expect { subject }.to raise_error(expected_error)
    end
  end

  describe '#user_revert', :freeze_time do
    let(:sha) { '54cec5282aa9f21856362fe321c800c236a61615' }
    let(:branch_name) { 'master' }
    let(:revert_message) { 'revert message' }
    let(:time) { Time.now.utc }

    let(:branch_update) do
      Gitaly::OperationBranchUpdate.new(
        commit_id: sha,
        repo_created: false,
        branch_created: false
      )
    end

    let(:request) do
      Gitaly::UserRevertRequest.new(
        repository: repository.gitaly_repository,
        user: gitaly_user,
        commit: repository.commit.to_gitaly_commit,
        branch_name: branch_name,
        start_branch_name: branch_name,
        start_repository: repository.gitaly_repository,
        message: revert_message,
        timestamp: Google::Protobuf::Timestamp.new(seconds: time.to_i)
      )
    end

    let(:response) { Gitaly::UserRevertResponse.new(branch_update: branch_update) }

    subject do
      client.user_revert(
        user: user,
        commit: repository.commit,
        branch_name: branch_name,
        message: revert_message,
        start_branch_name: branch_name,
        start_repository: repository
      )
    end

    it 'sends a user_revert message and returns a BranchUpdate' do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_revert).with(request, kind_of(Hash))
                                 .and_return(response)

      expect(subject).to be_a(Gitlab::Git::OperationService::BranchUpdate)
      expect(subject.newrev).to be_present
      expect(subject.repo_created).to be(false)
      expect(subject.branch_created).to be(false)
    end

    context 'when errors are raised' do
      let(:response_class) { Gitaly::UserRevertResponse }

      before do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_revert).with(kind_of(Gitaly::UserRevertRequest), kind_of(Hash))
                                   .and_return(response)
      end

      it_behaves_like 'cherry pick and revert errors'
    end

    context 'when MergeConflictError is raised' do
      let(:raised_error) do
        new_detailed_error(
          GRPC::Core::StatusCodes::FAILED_PRECONDITION,
          'revert: there are conflicting files',
          Gitaly::UserRevertError.new(
            merge_conflict: Gitaly::MergeConflictError.new
          )
        )
      end

      let(:expected_error) { Gitlab::Git::Repository::CreateTreeError }

      it_behaves_like '#user_revert with a gRPC error'
    end

    context 'when ChangesAlreadyAppliedError is raised' do
      let(:raised_error) do
        new_detailed_error(
          GRPC::Core::StatusCodes::FAILED_PRECONDITION,
          'revert: could not apply because the result was empty',
          Gitaly::UserRevertError.new(
            changes_already_applied: Gitaly::ChangesAlreadyAppliedError.new
          )
        )
      end

      let(:expected_error) { Gitlab::Git::Repository::CreateTreeError }

      it_behaves_like '#user_revert with a gRPC error'
    end

    context 'when NotAncestorError is raised' do
      let(:raised_error) do
        new_detailed_error(
          GRPC::Core::StatusCodes::FAILED_PRECONDITION,
          'revert: branch diverged',
          Gitaly::UserRevertError.new(
            not_ancestor: Gitaly::NotAncestorError.new
          )
        )
      end

      let(:expected_error) { Gitlab::Git::CommitError }

      it_behaves_like '#user_revert with a gRPC error'
    end

    context 'when CustomHookError is raised' do
      let(:raised_error) do
        new_detailed_error(
          GRPC::Core::StatusCodes::PERMISSION_DENIED,
          'revert: custom hook error',
          Gitaly::UserRevertError.new(
            custom_hook: Gitaly::CustomHookError.new
          )
        )
      end

      let(:expected_error) { Gitlab::Git::PreReceiveError }

      it_behaves_like '#user_revert with a gRPC error'
    end

    context 'when a non-detailed gRPC error is raised' do
      let(:raised_error) { GRPC::Internal.new('non-detailed error') }
      let(:expected_error) { GRPC::Internal }
      let(:expected_error_message) {}

      it_behaves_like '#user_revert with a gRPC error'
    end
  end

  describe '#rebase' do
    subject do
      client.rebase(
        user,
        '',
        branch: 'feature',
        branch_sha: '0b4bc9a49b562e85de7cc9e834518ea6828729b9',
        remote_repository: repository,
        remote_branch: 'master'
      ) {}
    end

    context 'with clean repository' do
      let(:project) { create(:project, :repository) }

      it 'succeeds' do
        expect(subject).to be_present
      end

      it 'receives a bad status' do
        expect(client).to receive(:gitaly_client_call)
          .and_wrap_original { |original, *args, **kwargs|
            response_enum = original.call(*args, **kwargs)
            Enumerator.new do |y|
              y << response_enum.next
              y << response_enum.next
              raise 'bad status'
            end
          }

        expect { subject }.to raise_error(RuntimeError, 'bad status')
      end

      it 'receives an unexpected response' do
        expect(client).to receive(:gitaly_client_call)
          .and_wrap_original { |original, *args, **kwargs|
            response_enum = original.call(*args, **kwargs)
            Enumerator.new do |y|
              y << response_enum.next
              y << response_enum.next
              y << 'unexpected response'
            end
          }

        expect { subject }.to raise_error(RuntimeError, 'expected response stream to finish')
      end
    end

    shared_examples '#rebase with an error' do
      it 'raises a GitError exception' do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_rebase_confirmable)
          .and_raise(raised_error)

        expect { subject }.to raise_error(expected_error)
      end
    end

    context 'when AccessError is raised' do
      let(:raised_error) do
        new_detailed_error(
          GRPC::Core::StatusCodes::INTERNAL,
          'something failed',
          Gitaly::UserRebaseConfirmableError.new(
            access_check: Gitaly::AccessCheckError.new(
              error_message: 'something went wrong'
            )))
      end

      let(:expected_error) { Gitlab::Git::PreReceiveError }

      it_behaves_like '#rebase with an error'
    end

    context 'when RebaseConflictError is raised' do
      let(:raised_error) do
        new_detailed_error(
          GRPC::Core::StatusCodes::INTERNAL,
          'something failed',
          Gitaly::UserSquashError.new(
            rebase_conflict: Gitaly::MergeConflictError.new(
              conflicting_files: ['conflicting-file']
            )))
      end

      let(:expected_error) { Gitlab::Git::Repository::GitError }

      it_behaves_like '#rebase with an error'
    end

    context 'when non-detailed gRPC error is raised' do
      let(:raised_error) do
        GRPC::Internal.new('non-detailed error')
      end

      let(:expected_error) { GRPC::Internal }

      it_behaves_like '#rebase with an error'
    end
  end

  describe '#user_rebase_to_ref' do
    let(:first_parent_ref) { 'refs/heads/my-branch' }
    let(:source_sha) { 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660' }
    let(:target_ref) { 'refs/merge-requests/x/merge' }
    let(:response) { Gitaly::UserRebaseToRefResponse.new(commit_id: 'new-commit-id') }

    let(:payload) do
      { source_sha: source_sha, target_ref: target_ref, first_parent_ref: first_parent_ref }
    end

    it 'sends a user_rebase_to_ref message' do
      freeze_time do
        expect_any_instance_of(Gitaly::OperationService::Stub).to receive(:user_rebase_to_ref) do |_, request, options|
          expect(options).to be_kind_of(Hash)
          expect(request.to_h).to(
            eq(
              payload.merge(
                {
                  expected_old_oid: "",
                  repository: repository.gitaly_repository.to_h,
                  user: Gitlab::Git::User.from_gitlab(user).to_gitaly.to_h,
                  timestamp: { nanos: 0, seconds: Time.current.to_i }
                }
              )
            )
          )
        end.and_return(response)

        client.user_rebase_to_ref(user, **payload)
      end
    end
  end

  describe '#user_squash' do
    let(:start_sha) { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }
    let(:end_sha) { '54cec5282aa9f21856362fe321c800c236a61615' }
    let(:commit_message) { 'Squash message' }

    let(:time) do
      Time.now.utc
    end

    let(:request) do
      Gitaly::UserSquashRequest.new(
        repository: repository.gitaly_repository,
        user: gitaly_user,
        start_sha: start_sha,
        end_sha: end_sha,
        author: gitaly_user,
        commit_message: commit_message,
        timestamp: Google::Protobuf::Timestamp.new(seconds: time.to_i)
      )
    end

    let(:squash_sha) { 'f00' }
    let(:response) { Gitaly::UserSquashResponse.new(squash_sha: squash_sha) }

    subject do
      client.user_squash(user, start_sha, end_sha, user, commit_message, time)
    end

    it 'sends a user_squash message and returns the squash sha' do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_squash).with(request, kind_of(Hash))
        .and_return(response)

      expect(subject).to eq(squash_sha)
    end

    shared_examples '#user_squash with an error' do
      it 'raises a GitError exception' do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_squash).with(request, kind_of(Hash))
          .and_raise(raised_error)

        expect { subject }.to raise_error(expected_error)
      end
    end

    context 'when ResolveRevisionError is raised' do
      let(:raised_error) do
        new_detailed_error(
          GRPC::Core::StatusCodes::INVALID_ARGUMENT,
          'something failed',
          Gitaly::UserSquashError.new(
            resolve_revision: Gitaly::ResolveRevisionError.new(
              revision: start_sha
            )))
      end

      let(:expected_error) { Gitlab::Git::Repository::GitError }

      it_behaves_like '#user_squash with an error'
    end

    context 'when RebaseConflictError is raised' do
      let(:raised_error) do
        new_detailed_error(
          GRPC::Core::StatusCodes::INTERNAL,
          'something failed',
          Gitaly::UserSquashError.new(
            rebase_conflict: Gitaly::MergeConflictError.new(
              conflicting_files: ['conflicting-file']
            )))
      end

      let(:expected_error) { Gitlab::Git::Repository::GitError }

      it_behaves_like '#user_squash with an error'
    end

    context 'when non-detailed gRPC error is raised' do
      let(:raised_error) do
        GRPC::Internal.new('non-detailed error')
      end

      let(:expected_error) { GRPC::Internal }

      it_behaves_like '#user_squash with an error'
    end
  end

  describe '#user_commit_files' do
    let(:force) { false }
    let(:start_sha) { nil }
    let(:sign) { true }
    let(:target_sha) { nil }

    subject do
      client.user_commit_files(
        user, 'my-branch', 'Commit files message', [], 'janedoe@example.com', 'Jane Doe',
        'master', repository, force, start_sha, sign, target_sha)
    end

    context 'when UserCommitFiles RPC is called' do
      let(:force) { true }
      let(:start_sha) { project.commit.id }
      let(:sign) { false }
      let(:target_sha) { 'target_sha' }

      it 'successfully builds the header' do
        expect_any_instance_of(Gitaly::OperationService::Stub).to receive(:user_commit_files) do |_, req_enum|
          header = req_enum.first.header

          expect(header.force).to eq(force)
          expect(header.start_sha).to eq(start_sha)
          expect(header.sign).to eq(sign)
          expect(header.expected_old_oid).to eq(target_sha)
        end.and_return(Gitaly::UserCommitFilesResponse.new)

        subject
      end
    end

    context 'with unstructured errors' do
      before do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_commit_files).with(kind_of(Enumerator), kind_of(Hash))
          .and_return(response)
      end

      context 'when a pre_receive_error is present' do
        let(:response) { Gitaly::UserCommitFilesResponse.new(pre_receive_error: "GitLab: something failed") }

        it 'raises a PreReceiveError' do
          expect { subject }.to raise_error(Gitlab::Git::PreReceiveError, "something failed")
        end
      end

      context 'when an index_error is present' do
        let(:response) { Gitaly::UserCommitFilesResponse.new(index_error: "something failed") }

        it 'raises an IndexError' do
          expect { subject }.to raise_error(Gitlab::Git::Index::IndexError, "something failed")
        end
      end

      context 'when branch_update is nil' do
        let(:response) { Gitaly::UserCommitFilesResponse.new }

        it { expect(subject).to be_nil }
      end
    end

    context 'with structured errors' do
      context 'with AccessCheckError' do
        before do
          expect_any_instance_of(Gitaly::OperationService::Stub)
            .to receive(:user_commit_files).with(kind_of(Enumerator), kind_of(Hash))
            .and_raise(raised_error)
        end

        let(:raised_error) do
          new_detailed_error(
            GRPC::Core::StatusCodes::PERMISSION_DENIED,
            "error updating file",
            Gitaly::UserCommitFilesError.new(
              access_check: Gitaly::AccessCheckError.new(
                error_message: "something went wrong"
              )))
        end

        it 'raises a PreReceiveError' do
          expect { subject }.to raise_error do |error|
            expect(error).to be_a(Gitlab::Git::PreReceiveError)
            expect(error.message).to eq("something went wrong")
          end
        end
      end

      context 'with IndexError' do
        let(:status_code) { nil }
        let(:expected_error) { nil }

        let(:structured_error) do
          new_detailed_error(
            status_code,
            "unused error message",
            expected_error)
        end

        shared_examples '#user_commit_files failure' do
          it 'raises an IndexError' do
            expect_any_instance_of(Gitaly::OperationService::Stub)
              .to receive(:user_commit_files).with(kind_of(Enumerator), kind_of(Hash))
              .and_raise(structured_error)

            expect { subject }.to raise_error do |error|
              expect(error).to be_a(Gitlab::Git::Index::IndexError)
              expect(error.message).to eq(expected_message)
            end
          end
        end

        context 'with missing file' do
          let(:status_code) { GRPC::Core::StatusCodes::NOT_FOUND }
          let(:expected_message) { "A file with this name doesn't exist" }
          let(:expected_error) do
            Gitaly::UserCommitFilesError.new(
              index_update: Gitaly::IndexError.new(
                path: "README.md",
                error_type: Gitaly::IndexError::ErrorType::ERROR_TYPE_FILE_NOT_FOUND
              ))
          end

          it_behaves_like '#user_commit_files failure'
        end

        context 'with existing directory' do
          let(:status_code) { GRPC::Core::StatusCodes::ALREADY_EXISTS }
          let(:expected_message) { "A directory with this name already exists" }
          let(:expected_error) do
            Gitaly::UserCommitFilesError.new(
              index_update: Gitaly::IndexError.new(
                path: "dir1",
                error_type: Gitaly::IndexError::ErrorType::ERROR_TYPE_DIRECTORY_EXISTS
              ))
          end

          it_behaves_like '#user_commit_files failure'
        end

        context 'with existing file' do
          let(:status_code) { GRPC::Core::StatusCodes::ALREADY_EXISTS }
          let(:expected_message) { "A file with this name already exists" }
          let(:expected_error) do
            Gitaly::UserCommitFilesError.new(
              index_update: Gitaly::IndexError.new(
                path: "README.md",
                error_type: Gitaly::IndexError::ErrorType::ERROR_TYPE_FILE_EXISTS
              ))
          end

          it_behaves_like '#user_commit_files failure'
        end

        context 'with invalid path' do
          let(:status_code) { GRPC::Core::StatusCodes::INVALID_ARGUMENT }
          let(:expected_message) { "invalid path: 'invalid://file/name'" }
          let(:expected_error) do
            Gitaly::UserCommitFilesError.new(
              index_update: Gitaly::IndexError.new(
                path: "invalid://file/name",
                error_type: Gitaly::IndexError::ErrorType::ERROR_TYPE_INVALID_PATH
              ))
          end

          it_behaves_like '#user_commit_files failure'
        end

        context 'with directory traversal' do
          let(:status_code) { GRPC::Core::StatusCodes::INVALID_ARGUMENT }
          let(:expected_message) { "Path cannot include directory traversal" }
          let(:expected_error) do
            Gitaly::UserCommitFilesError.new(
              index_update: Gitaly::IndexError.new(
                path: "../../../../etc/shadow",
                error_type: Gitaly::IndexError::ErrorType::ERROR_TYPE_DIRECTORY_TRAVERSAL
              ))
          end

          it_behaves_like '#user_commit_files failure'
        end

        context 'with empty path' do
          let(:status_code) { GRPC::Core::StatusCodes::INVALID_ARGUMENT }
          let(:expected_message) { "You must provide a file path" }
          let(:expected_error) do
            Gitaly::UserCommitFilesError.new(
              index_update: Gitaly::IndexError.new(
                path: "",
                error_type: Gitaly::IndexError::ErrorType::ERROR_TYPE_EMPTY_PATH
              ))
          end

          it_behaves_like '#user_commit_files failure'
        end

        context 'with unspecified error' do
          let(:status_code) { GRPC::Core::StatusCodes::INVALID_ARGUMENT }
          let(:expected_message) { "Unknown error performing git operation" }
          let(:expected_error) do
            Gitaly::UserCommitFilesError.new(
              index_update: Gitaly::IndexError.new(
                path: "",
                error_type: Gitaly::IndexError::ErrorType::ERROR_TYPE_UNSPECIFIED
              ))
          end

          it_behaves_like '#user_commit_files failure'
        end

        context 'with an exception without the detailed error' do
          before do
            expect_any_instance_of(Gitaly::OperationService::Stub)
              .to receive(:user_commit_files).with(kind_of(Enumerator), kind_of(Hash))
              .and_raise(raised_error)
          end

          context 'with an index error from libgit2' do
            let(:raised_error) do
              GRPC::Internal.new('invalid path: .git/foo')
            end

            it 'raises IndexError' do
              expect { subject }.to raise_error do |error|
                expect(error).to be_a(Gitlab::Git::Index::IndexError)
                expect(error.message).to eq('invalid path: .git/foo')
              end
            end
          end

          context 'with a generic error' do
            let(:raised_error) do
              GRPC::PermissionDenied.new
            end

            it 'raises PermissionDenied' do
              expect { subject }.to raise_error(GRPC::PermissionDenied)
            end
          end
        end
      end

      context 'with CustomHookError' do
        before do
          expect_any_instance_of(Gitaly::OperationService::Stub)
            .to receive(:user_commit_files).with(kind_of(Enumerator), kind_of(Hash))
            .and_raise(raised_error)
        end

        let(:raised_error) do
          new_detailed_error(
            GRPC::Core::StatusCodes::PERMISSION_DENIED,
            "error updating file",
            Gitaly::UserCommitFilesError.new(
              custom_hook: Gitaly::CustomHookError.new(
                stdout: "some stdout",
                stderr: "GitLab: some custom hook error message",
                hook_type: Gitaly::CustomHookError::HookType::HOOK_TYPE_PRERECEIVE
              )))
        end

        it 'raises a PreReceiveError' do
          expect { subject }.to raise_error do |error|
            expect(error).to be_a(Gitlab::Git::PreReceiveError)
            expect(error.message).to eq("some custom hook error message")
          end
        end
      end

      context 'with an invalid target_sha' do
        context 'when the target_sha is not in a valid format' do
          let(:target_sha) { 'asdf' }

          it 'raises CommandError' do
            expect { subject }.to raise_error(Gitlab::Git::CommandError)
          end
        end

        context 'when the target_sha is valid but not present in the repo' do
          let(:target_sha) { '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff0' }

          it 'raises CommandError' do
            expect { subject }.to raise_error(Gitlab::Git::CommandError)
          end
        end

        context 'when the target_sha is present in the repo but is not the latest' do
          let(:target_sha) { '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9' }

          it 'raises FailedPrecondition' do
            expect { subject }.to raise_error(GRPC::FailedPrecondition)
          end
        end
      end
    end
  end

  describe '#user_commit_patches' do
    let(:patches_folder) { Rails.root.join('spec/fixtures/patchfiles') }
    let(:patch_content) do
      patch_names.map { |name| File.read(File.join(patches_folder, name)) }.join("\n")
    end

    let(:patch_names) { %w[0001-This-does-not-apply-to-the-feature-branch.patch] }
    let(:branch_name) { 'branch-with-patches' }
    let(:target_sha) { nil }

    subject(:commit_patches) do
      client.user_commit_patches(user,
        branch_name: branch_name,
        patches: patch_content,
        target_sha: target_sha
      )
    end

    it 'applies the patch correctly' do
      branch_update = commit_patches

      expect(branch_update).to be_branch_created

      commit = repository.commit(branch_update.newrev)
      expect(commit.author_email).to eq('patchuser@gitlab.org')
      expect(commit.committer_email).to eq(user.email)
      expect(commit.message.chomp).to eq('This does not apply to the `feature` branch')
    end

    context 'when the patch could not be applied' do
      let(:patch_names) { %w[0001-This-does-not-apply-to-the-feature-branch.patch] }
      let(:branch_name) { 'feature' }

      it 'raises the correct error' do
        expect { commit_patches }.to raise_error(GRPC::FailedPrecondition)
      end
    end

    context 'when an invalid target_sha is provided' do
      let(:target_sha) { '2df2bff3c5d39d69c49c947a6972212731e8146f' }

      it 'raises the correct error' do
        expect { commit_patches }.to raise_error(GRPC::Internal)
      end
    end
  end

  describe '#add_tag' do
    let(:tag_name) { 'some-tag' }
    let(:tag_message) { nil }
    let(:target) { 'master' }

    subject(:add_tag) do
      client.add_tag(tag_name, user, target, tag_message)
    end

    context 'without tag message' do
      let(:tag_name) { 'lightweight-tag' }

      it 'creates a lightweight tag' do
        tag = add_tag
        expect(tag.name).to eq(tag_name)
        expect(tag.message).to eq('')
      end
    end

    context 'with tag message' do
      let(:tag_name) { 'annotated-tag' }
      let(:tag_message) { "tag message" }

      it 'creates an annotated tag' do
        tag = add_tag
        expect(tag.name).to eq(tag_name)
        expect(tag.message).to eq(tag_message)
      end
    end

    context 'with preexisting tag' do
      let(:tag_name) { 'v1.0.0' }

      it 'raises a TagExistsError' do
        expect { add_tag }.to raise_error(Gitlab::Git::Repository::TagExistsError)
      end
    end

    context 'with invalid target' do
      let(:target) { 'refs/heads/does-not-exist' }

      it 'raises an InvalidRef error' do
        expect { add_tag }.to raise_error(Gitlab::Git::Repository::InvalidRef)
      end
    end

    context 'with internal error' do
      before do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_create_tag)
          .and_raise(GRPC::Internal.new('undetailed internal error'))
      end

      it 'raises an Internal error' do
        expect { add_tag }.to raise_error do |error|
          expect(error).to be_a(GRPC::Internal)
          expect(error.details).to eq('undetailed internal error')
        end
      end
    end

    context 'with structured errors' do
      before do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_create_tag)
          .and_raise(structured_error)
      end

      context 'with ReferenceExistsError' do
        let(:structured_error) do
          new_detailed_error(
            GRPC::Core::StatusCodes::ALREADY_EXISTS,
            'tag exists already',
            Gitaly::UserCreateTagError.new(
              reference_exists: Gitaly::ReferenceExistsError.new(
                reference_name: tag_name,
                oid: 'something'
              )))
        end

        it 'raises a TagExistsError' do
          expect { add_tag }.to raise_error(Gitlab::Git::Repository::TagExistsError)
        end
      end

      context 'with AccessCheckError' do
        let(:structured_error) do
          new_detailed_error(
            GRPC::Core::StatusCodes::PERMISSION_DENIED,
            "error creating tag",
            Gitaly::UserCreateTagError.new(
              access_check: Gitaly::AccessCheckError.new(
                error_message: "You are not allowed to create this tag.",
                protocol: "web",
                user_id: "user-15",
                changes: "df15b32277d2c55c6c595845a87109b09c913c556 5d6e0f935ad9240655f64e883cd98fad6f9a17ee refs/tags/v1.0.0\n"
              )))
        end

        it 'raises a PreReceiveError' do
          expect { add_tag }.to raise_error do |error|
            expect(error).to be_a(Gitlab::Git::PreReceiveError)
            expect(error.message).to eq("You are not allowed to create this tag.")
          end
        end
      end

      context 'with CustomHookError' do
        let(:structured_error) do
          new_detailed_error(
            GRPC::Core::StatusCodes::PERMISSION_DENIED,
            "custom hook error",
            Gitaly::UserCreateTagError.new(
              custom_hook: Gitaly::CustomHookError.new(
                stdout: "some stdout",
                stderr: "GitLab: some custom hook error message",
                hook_type: Gitaly::CustomHookError::HookType::HOOK_TYPE_PRERECEIVE
              )))
        end

        it 'raises a PreReceiveError' do
          expect { add_tag }.to raise_error do |error|
            expect(error).to be_a(Gitlab::Git::PreReceiveError)
            expect(error.message).to eq("some custom hook error message")
          end
        end
      end
    end
  end
end
