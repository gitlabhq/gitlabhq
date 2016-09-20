require 'spec_helper'

describe Gitlab::Checks::ChangeAccess, lib: true do
  describe '#exec' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:user_access) { Gitlab::UserAccess.new(user, project: project) }
    let(:changes) do
      {
        oldrev: 'be93687618e4b132087f430a4d8fc3a609c9b77c',
        newrev: '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51',
        ref: 'refs/heads/master'
      }
    end

    subject { described_class.new(changes, project: project, user_access: user_access).exec }

    before { allow(user_access).to receive(:can_do_action?).with(:push_code).and_return(true) }

    context 'without failed checks' do
      it "doesn't return any error" do
        expect(subject.status).to be(true)
      end
    end

    context 'when the user is not allowed to push code' do
      it 'returns an error' do
        expect(user_access).to receive(:can_do_action?).with(:push_code).and_return(false)

        expect(subject.status).to be(false)
        expect(subject.message).to eq('You are not allowed to push code to this project.')
      end
    end

    context 'tags check' do
      let(:changes) do
        {
          oldrev: 'be93687618e4b132087f430a4d8fc3a609c9b77c',
          newrev: '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51',
          ref: 'refs/tags/v1.0.0'
        }
      end

      it 'returns an error if the user is not allowed to update tags' do
        expect(user_access).to receive(:can_do_action?).with(:admin_project).and_return(false)

        expect(subject.status).to be(false)
        expect(subject.message).to eq('You are not allowed to change existing tags on this project.')
      end
    end

    context 'protected branches check' do
      before do
        allow(project).to receive(:protected_branch?).with('master').and_return(true)
      end

      it 'returns an error if the user is not allowed to do forced pushes to protected branches' do
        expect(Gitlab::Checks::ForcePush).to receive(:force_push?).and_return(true)
        expect(user_access).to receive(:can_do_action?).with(:force_push_code_to_protected_branches).and_return(false)

        expect(subject.status).to be(false)
        expect(subject.message).to eq('You are not allowed to force push code to a protected branch on this project.')
      end

      it 'returns an error if the user is not allowed to merge to protected branches' do
        expect_any_instance_of(Gitlab::Checks::MatchingMergeRequest).to receive(:match?).and_return(true)
        expect(user_access).to receive(:can_merge_to_branch?).and_return(false)
        expect(user_access).to receive(:can_push_to_branch?).and_return(false)

        expect(subject.status).to be(false)
        expect(subject.message).to eq('You are not allowed to merge code into protected branches on this project.')
      end

      it 'returns an error if the user is not allowed to push to protected branches' do
        expect(user_access).to receive(:can_push_to_branch?).and_return(false)

        expect(subject.status).to be(false)
        expect(subject.message).to eq('You are not allowed to push code to protected branches on this project.')
      end

      context 'branch deletion' do
        let(:changes) do
          {
            oldrev: 'be93687618e4b132087f430a4d8fc3a609c9b77c',
            newrev: '0000000000000000000000000000000000000000',
            ref: 'refs/heads/master'
          }
        end

        it 'returns an error if the user is not allowed to delete protected branches' do
          expect(user_access).to receive(:can_do_action?).with(:remove_protected_branches).and_return(false)

          expect(subject.status).to be(false)
          expect(subject.message).to eq('You are not allowed to delete protected branches from this project.')
        end
      end
    end

    context 'push rules checks' do
      let(:project) { create(:project, :public, push_rule: push_rule) }

      before do
        allow(project.repository).to receive(:new_commits).and_return(
          project.repository.commits_between('be93687618e4b132087f430a4d8fc3a609c9b77c', '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51')
        )
      end

      context 'tag deletion' do
        let(:changes) do
          {
            oldrev: 'be93687618e4b132087f430a4d8fc3a609c9b77c',
            newrev: '0000000000000000000000000000000000000000',
            ref: 'refs/tags/v1.0.0'
          }
        end
        let(:push_rule) { create(:push_rule, deny_delete_tag: true) }

        before { allow(user_access).to receive(:can_do_action?).with(:admin_project).and_return(true) }

        it 'returns an error if the rule denies tag deletion' do
          expect(subject.status).to be(false)
          expect(subject.message).to eq('You can not delete a tag')
        end
      end

      context 'commit message rules' do
        let(:push_rule) { create(:push_rule, :commit_message) }

        it 'returns an error if the rule fails' do
          expect(subject.status).to be(false)
          expect(subject.message).to eq("Commit message does not follow the pattern '#{push_rule.commit_message_regex}'")
        end
      end

      context 'author email rules' do
        let(:push_rule) { create(:push_rule, author_email_regex: '.*@valid.com') }

        before do
          allow_any_instance_of(Commit).to receive(:committer_email).and_return('mike@valid.com')
          allow_any_instance_of(Commit).to receive(:author_email).and_return('mike@valid.com')
        end

        it 'returns an error if the rule fails for the committer' do
          allow_any_instance_of(Commit).to receive(:committer_email).and_return('ana@invalid.com')

          expect(subject.status).to be(false)
          expect(subject.message).to eq("Committer's email 'ana@invalid.com' does not follow the pattern '.*@valid.com'")
        end

        it 'returns an error if the rule fails for the author' do
          allow_any_instance_of(Commit).to receive(:author_email).and_return('joan@invalid.com')

          expect(subject.status).to be(false)
          expect(subject.message).to eq("Author's email 'joan@invalid.com' does not follow the pattern '.*@valid.com'")
        end
      end

      context 'existing member rules' do
        let(:push_rule) { create(:push_rule, member_check: true) }

        before do
          allow(User).to receive(:existing_member?).and_return(false)
          allow_any_instance_of(Commit).to receive(:author_email).and_return('some@mail.com')
        end

        it 'returns an error if the commit author is not a GitLab member' do
          expect(subject.status).to be(false)
          expect(subject.message).to eq("Author 'some@mail.com' is not a member of team")
        end
      end

      context 'file name rules' do
        # Notice that the commit used creates a file named 'README'
        context 'file name regex check' do
          let(:push_rule) { create(:push_rule, file_name_regex: 'READ*') }

          it "returns an error if a new or renamed filed doesn't match the file name regex" do
            expect(subject.status).to be(false)
            expect(subject.message).to eq("File name README was blacklisted by the pattern READ*.")
          end
        end

        context 'blacklisted files check' do
          let(:push_rule) { create(:push_rule, prevent_secrets: true) }
          let(:checker) { described_class.new(changes, project: project, user_access: user_access) }

          it "returns status true if there is no blacklisted files" do
            new_rev = nil

            white_listed =
              [
                'readme.txt', 'any/ida_rsa.pub', 'any/id_dsa.pub', 'any_2/id_ed25519.pub',
                'random_file.pdf', 'folder/id_ecdsa.pub', 'docs/aws/credentials.md', 'ending_withhistory'
              ]

            white_listed.each do |file_path|
              old_rev = 'be93687618e4b132087f430a4d8fc3a609c9b77c'
              old_rev = new_rev if new_rev
              new_rev = project.repository.commit_file(user, file_path, "commit #{file_path}", "commit #{file_path}", "master", false)

              allow(project.repository).to receive(:new_commits).and_return(
                project.repository.commits_between(old_rev, new_rev)
              )

              expect(checker.exec.status).to be(true)
            end
          end

          it "returns an error if a new or renamed filed doesn't match the file name regex" do
            new_rev = nil

            black_listed =
              [
                'aws/credentials', '.ssh/personal_rsa', 'config/server_rsa', '.ssh/id_rsa', '.ssh/id_dsa',
                '.ssh/personal_dsa', 'config/server_ed25519', 'any/id_ed25519', '.ssh/personal_ecdsa', 'config/server_ecdsa',
                'any_place/id_ecdsa', 'some_pLace/file.key', 'other_PlAcE/other_file.pem', 'bye_bug.history, pg_sql_history'
              ]

            black_listed.each do |file_path|
              old_rev = 'be93687618e4b132087f430a4d8fc3a609c9b77c'
              old_rev = new_rev if new_rev
              new_rev = project.repository.commit_file(user, file_path, "commit #{file_path}", "commit #{file_path}", "master", false)

              allow(project.repository).to receive(:new_commits).and_return(
                project.repository.commits_between(old_rev, new_rev)
              )

              result = checker.exec

              expect(result.status).to be(false)
              expect(result.message).to include("File name #{file_path} was blacklisted by the pattern")
            end
          end
        end
      end

      context 'max file size rules' do
        let(:push_rule) { create(:push_rule, max_file_size: 1) }

        before { allow_any_instance_of(Blob).to receive(:size).and_return(2.megabytes) }

        it 'returns an error if file exceeds the maximum file size' do
          expect(subject.status).to be(false)
          expect(subject.message).to eq("File \"README\" is larger than the allowed size of 1 MB")
        end
      end
    end

    context 'file lock rules' do
      let!(:path_lock) { create(:path_lock, path: 'README', project: project) }

      before do
        allow_any_instance_of(PathLocksHelper).to receive(:license_allows_file_locks?).and_return(true)

        allow(project.repository).to receive(:new_commits).and_return(
          project.repository.commits_between('be93687618e4b132087f430a4d8fc3a609c9b77c', '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51')
        )
      end
      it 'returns an error if the changes update a path locked by another user' do
        expect(subject.status).to be(false)
        expect(subject.message).to eq("The path 'README' is locked by #{path_lock.user.name}")
      end
    end
  end
end
