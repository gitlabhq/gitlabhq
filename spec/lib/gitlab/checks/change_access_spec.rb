require 'spec_helper'

describe Gitlab::Checks::ChangeAccess do
  describe '#exec' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:user_access) { Gitlab::UserAccess.new(user, project: project) }
    let(:oldrev) { 'be93687618e4b132087f430a4d8fc3a609c9b77c' }
    let(:newrev) { '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51' }
    let(:ref) { 'refs/heads/master' }
    let(:changes) { { oldrev: oldrev, newrev: newrev, ref: ref } }
    let(:protocol) { 'ssh' }

    subject do
      described_class.new(
        changes,
        project: project,
        user_access: user_access,
        protocol: protocol
      ).exec
    end

    before do
      project.add_developer(user)
    end

    context 'without failed checks' do
      it "doesn't raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context 'when the user is not allowed to push code' do
      it 'raises an error' do
        expect(user_access).to receive(:can_do_action?).with(:push_code).and_return(false)

        expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You are not allowed to push code to this project.')
      end
    end

    context 'tags check' do
      let(:ref) { 'refs/tags/v1.0.0' }

      it 'raises an error if the user is not allowed to update tags' do
        allow(user_access).to receive(:can_do_action?).with(:push_code).and_return(true)
        expect(user_access).to receive(:can_do_action?).with(:admin_project).and_return(false)

        expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You are not allowed to change existing tags on this project.')
      end

      context 'with protected tag' do
        let!(:protected_tag) { create(:protected_tag, project: project, name: 'v*') }

        context 'as master' do
          before do
            project.add_master(user)
          end

          context 'deletion' do
            let(:oldrev) { 'be93687618e4b132087f430a4d8fc3a609c9b77c' }
            let(:newrev) { '0000000000000000000000000000000000000000' }

            it 'is prevented' do
              expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, /cannot be deleted/)
            end
          end

          context 'update' do
            let(:oldrev) { 'be93687618e4b132087f430a4d8fc3a609c9b77c' }
            let(:newrev) { '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51' }

            it 'is prevented' do
              expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, /cannot be updated/)
            end
          end
        end

        context 'creation' do
          let(:oldrev) { '0000000000000000000000000000000000000000' }
          let(:newrev) { '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51' }
          let(:ref) { 'refs/tags/v9.1.0' }

          it 'prevents creation below access level' do
            expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, /allowed to create this tag as it is protected/)
          end

          context 'when user has access' do
            let!(:protected_tag) { create(:protected_tag, :developers_can_create, project: project, name: 'v*') }

            it 'allows tag creation' do
              expect { subject }.not_to raise_error
            end
          end
        end
      end
    end

    context 'branches check' do
      context 'trying to delete the default branch' do
        let(:newrev) { '0000000000000000000000000000000000000000' }
        let(:ref) { 'refs/heads/master' }

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'The default branch of a project cannot be deleted.')
        end
      end

      context 'protected branches check' do
        before do
          allow(ProtectedBranch).to receive(:protected?).with(project, 'master').and_return(true)
          allow(ProtectedBranch).to receive(:protected?).with(project, 'feature').and_return(true)
        end

        it 'raises an error if the user is not allowed to do forced pushes to protected branches' do
          expect(Gitlab::Checks::ForcePush).to receive(:force_push?).and_return(true)

          expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You are not allowed to force push code to a protected branch on this project.')
        end

        it 'raises an error if the user is not allowed to merge to protected branches' do
          expect_any_instance_of(Gitlab::Checks::MatchingMergeRequest).to receive(:match?).and_return(true)
          expect(user_access).to receive(:can_merge_to_branch?).and_return(false)
          expect(user_access).to receive(:can_push_to_branch?).and_return(false)

          expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You are not allowed to merge code into protected branches on this project.')
        end

        it 'raises an error if the user is not allowed to push to protected branches' do
          expect(user_access).to receive(:can_push_to_branch?).and_return(false)

          expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You are not allowed to push code to protected branches on this project.')
        end

        context 'branch deletion' do
          let(:newrev) { '0000000000000000000000000000000000000000' }
          let(:ref) { 'refs/heads/feature' }

          context 'if the user is not allowed to delete protected branches' do
            it 'raises an error' do
              expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You are not allowed to delete protected branches from this project. Only a project master or owner can delete a protected branch.')
            end
          end

          context 'if the user is allowed to delete protected branches' do
            before do
              project.add_master(user)
            end

            context 'through the web interface' do
              let(:protocol) { 'web' }

              it 'allows branch deletion' do
                expect { subject }.not_to raise_error
              end
            end

            context 'over SSH or HTTP' do
              it 'raises an error' do
                expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You can only delete protected branches using the web interface.')
              end
            end
          end
        end
      end
    end

    context 'push rules checks' do
      shared_examples 'check ignored when push rule unlicensed' do
        before do
          stub_licensed_features(push_rules: false)
        end

        it { is_expected.to be_truthy }
      end

      let(:project) { create(:project, :public, :repository, push_rule: push_rule) }

      before do
        allow(project.repository).to receive(:new_commits).and_return(
          project.repository.commits_between('be93687618e4b132087f430a4d8fc3a609c9b77c', '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51')
        )
      end

      context 'tag deletion' do
        let(:push_rule) { create(:push_rule, deny_delete_tag: true) }
        let(:oldrev) { 'be93687618e4b132087f430a4d8fc3a609c9b77c' }
        let(:newrev) { '0000000000000000000000000000000000000000' }
        let(:ref) { 'refs/tags/v1.0.0' }

        before do
          project.add_master(user)
        end

        it_behaves_like 'check ignored when push rule unlicensed'

        it 'returns an error if the rule denies tag deletion' do
          expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You cannot delete a tag')
        end

        context 'when tag is deleted in web UI' do
          let(:protocol) { 'web' }

          it 'ignores the push rule' do
            expect(subject).to be_truthy
          end
        end
      end

      context 'commit message rules' do
        let(:push_rule) { create(:push_rule, :commit_message) }

        it_behaves_like 'check ignored when push rule unlicensed'

        it 'returns an error if the rule fails' do
          expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "Commit message does not follow the pattern '#{push_rule.commit_message_regex}'")
        end
      end

      context 'author email rules' do
        let(:push_rule) { create(:push_rule, author_email_regex: '.*@valid.com') }

        before do
          allow_any_instance_of(Commit).to receive(:committer_email).and_return('mike@valid.com')
          allow_any_instance_of(Commit).to receive(:author_email).and_return('mike@valid.com')
        end

        it_behaves_like 'check ignored when push rule unlicensed'

        it 'returns an error if the rule fails for the committer' do
          allow_any_instance_of(Commit).to receive(:committer_email).and_return('ana@invalid.com')

          expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "Committer's email 'ana@invalid.com' does not follow the pattern '.*@valid.com'")
        end

        it 'returns an error if the rule fails for the author' do
          allow_any_instance_of(Commit).to receive(:author_email).and_return('joan@invalid.com')

          expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "Author's email 'joan@invalid.com' does not follow the pattern '.*@valid.com'")
        end
      end

      context 'branch name rules' do
        let(:push_rule) { create(:push_rule, branch_name_regex: '^(w*)$') }
        let(:ref) { 'refs/heads/a-branch-that-is-not-allowed' }

        it_behaves_like 'check ignored when push rule unlicensed'

        it 'rejects the branch that is not allowed' do
          expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "Branch name does not follow the pattern '^(w*)$'")
        end

        context 'when the ref is not a branch ref' do
          let(:ref) { 'a/ref/thats/not/abranch' }

          it 'allows the creation' do
            expect { subject }.not_to raise_error
          end
        end

        context 'when no commits are present' do
          before do
            allow(project.repository).to receive(:new_commits) { [] }
          end

          it 'rejects the branch that is not allowed' do
            expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "Branch name does not follow the pattern '^(w*)$'")
          end
        end
      end

      context 'existing member rules' do
        let(:push_rule) { create(:push_rule, member_check: true) }

        before do
          allow(User).to receive(:existing_member?).and_return(false)
          allow_any_instance_of(Commit).to receive(:author_email).and_return('some@mail.com')
        end

        it_behaves_like 'check ignored when push rule unlicensed'

        it 'returns an error if the commit author is not a GitLab member' do
          expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "Author 'some@mail.com' is not a member of team")
        end
      end

      context 'file name rules' do
        # Notice that the commit used creates a file named 'README'
        context 'file name regex check' do
          let(:push_rule) { create(:push_rule, file_name_regex: 'READ*') }

          it_behaves_like 'check ignored when push rule unlicensed'

          it "returns an error if a new or renamed filed doesn't match the file name regex" do
            expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "File name README was blacklisted by the pattern READ*.")
          end
        end

        context 'blacklisted files check' do
          let(:push_rule) { create(:push_rule, prevent_secrets: true) }

          it_behaves_like 'check ignored when push rule unlicensed'

          it "returns true if there is no blacklisted files" do
            new_rev = nil

            white_listed =
              [
                'readme.txt', 'any/ida_rsa.pub', 'any/id_dsa.pub', 'any_2/id_ed25519.pub',
                'random_file.pdf', 'folder/id_ecdsa.pub', 'docs/aws/credentials.md', 'ending_withhistory'
              ]

            white_listed.each do |file_path|
              old_rev = 'be93687618e4b132087f430a4d8fc3a609c9b77c'
              old_rev = new_rev if new_rev
              new_rev = project.repository.create_file(user, file_path, "commit #{file_path}", message: "commit #{file_path}", branch_name: "master")

              allow(project.repository).to receive(:new_commits).and_return(
                project.repository.commits_between(old_rev, new_rev)
              )

              expect(subject).to be_truthy
            end
          end

          it "returns an error if a new or renamed filed doesn't match the file name regex" do
            new_rev = nil

            black_listed =
              [
                'aws/credentials', '.ssh/personal_rsa', 'config/server_rsa', '.ssh/id_rsa', '.ssh/id_dsa',
                '.ssh/personal_dsa', 'config/server_ed25519', 'any/id_ed25519', '.ssh/personal_ecdsa', 'config/server_ecdsa',
                'any_place/id_ecdsa', 'some_pLace/file.key', 'other_PlAcE/other_file.pem', 'bye_bug.history', 'pg_sql_history'
              ]

            black_listed.each do |file_path|
              old_rev = 'be93687618e4b132087f430a4d8fc3a609c9b77c'
              old_rev = new_rev if new_rev
              new_rev = project.repository.create_file(user, file_path, "commit #{file_path}", message: "commit #{file_path}", branch_name: "master")

              allow(project.repository).to receive(:new_commits).and_return(
                project.repository.commits_between(old_rev, new_rev)
              )

              expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, /File name #{file_path} was blacklisted by the pattern/)
            end
          end
        end
      end

      context 'max file size rules' do
        let(:push_rule) { create(:push_rule, max_file_size: 1) }

        before do
          allow_any_instance_of(Blob).to receive(:size).and_return(2.megabytes)
        end

        it_behaves_like 'check ignored when push rule unlicensed'

        it 'returns an error if file exceeds the maximum file size' do
          expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "File \"README\" is larger than the allowed size of 1 MB")
        end
      end
    end

    context 'file lock rules' do
      let!(:path_lock) { create(:path_lock, path: 'README', project: project) }

      before do
        allow(project.repository).to receive(:new_commits).and_return(
          project.repository.commits_between('be93687618e4b132087f430a4d8fc3a609c9b77c', '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51')
        )
      end

      it 'returns an error if the changes update a path locked by another user' do
        expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "The path 'README' is locked by #{path_lock.user.name}")
      end
    end
  end
end
