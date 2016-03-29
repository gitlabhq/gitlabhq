require 'spec_helper'

describe Gitlab::GitAccess, lib: true do
  let(:access) { Gitlab::GitAccess.new(actor, project) }
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:actor) { user }
  let(:git_annex_changes) do
    ["6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/synced/git-annex",
     "6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/synced/named-branch"]
  end
  let(:git_annex_master_changes) { "6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/master" }

  describe 'can_push_to_branch?' do
    describe 'push to none protected branch' do
      it "returns true if user is a master" do
        project.team << [user, :master]
        expect(access.can_push_to_branch?("random_branch")).to be_truthy
      end

      it "returns true if user is a developer" do
        project.team << [user, :developer]
        expect(access.can_push_to_branch?("random_branch")).to be_truthy
      end

      it "returns false if user is a reporter" do
        project.team << [user, :reporter]
        expect(access.can_push_to_branch?("random_branch")).to be_falsey
      end
    end

    describe 'push to protected branch' do
      before do
        @branch = create :protected_branch, project: project
      end

      it "returns true if user is a master" do
        project.team << [user, :master]
        expect(access.can_push_to_branch?(@branch.name)).to be_truthy
      end

      it "returns false if user is a developer" do
        project.team << [user, :developer]
        expect(access.can_push_to_branch?(@branch.name)).to be_falsey
      end

      it "returns false if user is a reporter" do
        project.team << [user, :reporter]
        expect(access.can_push_to_branch?(@branch.name)).to be_falsey
      end
    end

    describe 'push to protected branch if allowed for developers' do
      before do
        @branch = create :protected_branch, project: project, developers_can_push: true
      end

      it "returns true if user is a master" do
        project.team << [user, :master]
        expect(access.can_push_to_branch?(@branch.name)).to be_truthy
      end

      it "returns true if user is a developer" do
        project.team << [user, :developer]
        expect(access.can_push_to_branch?(@branch.name)).to be_truthy
      end

      it "returns false if user is a reporter" do
        project.team << [user, :reporter]
        expect(access.can_push_to_branch?(@branch.name)).to be_falsey
      end
    end

  end

  describe 'download_access_check' do
    describe 'master permissions' do
      before { project.team << [user, :master] }

      context 'pull code' do
        subject { access.download_access_check }

        it { expect(subject.allowed?).to be_truthy }
      end
    end

    describe 'guest permissions' do
      before { project.team << [user, :guest] }

      context 'pull code' do
        subject { access.download_access_check }

        it { expect(subject.allowed?).to be_falsey }
      end
    end

    describe 'blocked user' do
      before do
        project.team << [user, :master]
        user.block
      end

      context 'pull code' do
        subject { access.download_access_check }

        it { expect(subject.allowed?).to be_falsey }
      end
    end

    describe 'without acccess to project' do
      context 'pull code' do
        subject { access.download_access_check }

        it { expect(subject.allowed?).to be_falsey }
      end
    end

    describe 'deploy key permissions' do
      let(:key) { create(:deploy_key) }
      let(:actor) { key }

      context 'pull code' do
        before { key.projects << project }
        subject { access.download_access_check }

        it { expect(subject.allowed?).to be_truthy }
      end
    end

    describe 'geo node key permissions' do
      let(:key) { build(:geo_node_key) }
      let(:actor) { key }

      context 'pull code' do
        subject { access.download_access_check }

        it { expect(subject.allowed?).to be_truthy }
      end
    end
  end

  describe 'push_access_check' do
    def protect_feature_branch
      create(:protected_branch, name: 'feature', project: project)
    end

    def changes
      {
        push_new_branch: "#{Gitlab::Git::BLANK_SHA} 570e7b2ab refs/heads/wow",
        push_master: '6f6d7e7ed 570e7b2ab refs/heads/master',
        push_protected_branch: '6f6d7e7ed 570e7b2ab refs/heads/feature',
        push_remove_protected_branch: "570e7b2ab #{Gitlab::Git::BLANK_SHA} "\
                                      'refs/heads/feature',
        push_tag: '6f6d7e7ed 570e7b2ab refs/tags/v1.0.0',
        push_new_tag: "#{Gitlab::Git::BLANK_SHA} 570e7b2ab refs/tags/v7.8.9",
        push_all: ['6f6d7e7ed 570e7b2ab refs/heads/master', '6f6d7e7ed 570e7b2ab refs/heads/feature']
      }
    end

    def self.permissions_matrix
      {
        master: {
          push_new_branch: true,
          push_master: true,
          push_protected_branch: true,
          push_remove_protected_branch: false,
          push_tag: true,
          push_new_tag: true,
          push_all: true,
        },

        developer: {
          push_new_branch: true,
          push_master: true,
          push_protected_branch: false,
          push_remove_protected_branch: false,
          push_tag: false,
          push_new_tag: true,
          push_all: false,
        },

        reporter: {
          push_new_branch: false,
          push_master: false,
          push_protected_branch: false,
          push_remove_protected_branch: false,
          push_tag: false,
          push_new_tag: false,
          push_all: false,
        },

        guest: {
          push_new_branch: false,
          push_master: false,
          push_protected_branch: false,
          push_remove_protected_branch: false,
          push_tag: false,
          push_new_tag: false,
          push_all: false,
        }
      }
    end

    def self.updated_permissions_matrix
      updated_permissions_matrix = permissions_matrix.dup
      updated_permissions_matrix[:developer][:push_protected_branch] = true
      updated_permissions_matrix[:developer][:push_all] = true
      updated_permissions_matrix
    end

    permissions_matrix.keys.each do |role|
      describe "#{role} access" do
        before { protect_feature_branch }
        before { project.team << [user, role] }

        permissions_matrix[role].each do |action, allowed|
          context action do
            subject { access.push_access_check(changes[action]) }

            it { expect(subject.allowed?).to allowed ? be_truthy : be_falsey }
          end
        end
      end
    end

    context "with enabled developers push to protected branches " do
      updated_permissions_matrix.keys.each do |role|
        describe "#{role} access" do
          before { create(:protected_branch, name: 'feature', developers_can_push: true, project: project) }
          before { project.team << [user, role] }

          updated_permissions_matrix[role].each do |action, allowed|
            context action do
              subject { access.push_access_check(changes[action]) }

              it { expect(subject.allowed?).to allowed ? be_truthy : be_falsey }
            end
          end
        end
      end
    end

    context "when license blocks changes" do
      before do
        allow(License).to receive(:block_changes?).and_return(true)
      end

      permissions_matrix.keys.each do |role|
        describe "#{role} access" do
          before { protect_feature_branch }
          before { project.team << [user, role] }

          permissions_matrix[role].each do |action, allowed|
            context action do
              subject { access.push_access_check(changes[action]) }

              it { expect(subject.allowed?).to be_falsey }
            end
          end
        end
      end
    end

    context "when in a secondary gitlab geo node" do
      before do
        allow(Gitlab::Geo).to receive(:enabled?) { true }
        allow(Gitlab::Geo).to receive(:secondary?) { true }
      end

      permissions_matrix.keys.each do |role|
        describe "#{role} access" do
          before { protect_feature_branch }
          before { project.team << [user, role] }

          permissions_matrix[role].each do |action, allowed|
            context action do
              subject { access.push_access_check(changes[action]) }

              it { expect(subject.allowed?).to be_falsey }
            end
          end
        end
      end
    end

    context "when using git annex" do
      before { project.team << [user, :master] }

      describe 'and gitlab geo is enabled in a secondary node' do
        before do
          allow(Gitlab.config.gitlab_shell).to receive(:git_annex_enabled).and_return(true)
          allow(Gitlab::Geo).to receive(:enabled?) { true }
          allow(Gitlab::Geo).to receive(:secondary?) { true }
        end

        it { expect(access.push_access_check(git_annex_changes)).not_to be_allowed }
      end

      describe 'and git hooks unset' do
        describe 'git annex enabled' do
          before { allow(Gitlab.config.gitlab_shell).to receive(:git_annex_enabled).and_return(true) }

          it { expect(access.push_access_check(git_annex_changes)).to be_allowed }
        end

        describe 'git annex disabled' do
          before { allow(Gitlab.config.gitlab_shell).to receive(:git_annex_enabled).and_return(false) }

          it { expect(access.push_access_check(git_annex_changes)).to be_allowed }
        end
      end

      describe 'and git hooks set' do
        before { project.create_git_hook }

        describe 'check commit author email' do
          before do
            project.git_hook.update(author_email_regex: "@only.com")
          end

          describe 'git annex enabled' do
            before { allow(Gitlab.config.gitlab_shell).to receive(:git_annex_enabled).and_return(true) }

            it { expect(access.push_access_check(git_annex_changes)).to be_allowed }
          end

          describe 'git annex enabled, push to master branch' do
            before do
              allow(Gitlab.config.gitlab_shell).to receive(:git_annex_enabled).and_return(true)
              allow_any_instance_of(Commit).to receive(:safe_message) { 'git-annex in me@host:~/repo' }
            end

            it { expect(access.push_access_check(git_annex_master_changes)).to be_allowed }
          end

          describe 'git annex disabled' do
            before { allow(Gitlab.config.gitlab_shell).to receive(:git_annex_enabled).and_return(false) }

            it { expect(access.push_access_check(git_annex_changes)).to_not be_allowed }
          end
        end

        describe 'check max file size' do
          before do
            allow_any_instance_of(Gitlab::Git::Blob).to receive(:size).and_return(5.megabytes.to_i)
            project.git_hook.update(max_file_size: 2)
          end

          describe 'git annex enabled' do
            before { allow(Gitlab.config.gitlab_shell).to receive(:git_annex_enabled).and_return(true) }

            it { expect(access.push_access_check(git_annex_changes)).to be_allowed }
          end

          describe 'git annex disabled' do
            before { allow(Gitlab.config.gitlab_shell).to receive(:git_annex_enabled).and_return(false) }

            it { expect(access.push_access_check(git_annex_changes)).to_not be_allowed }
          end
        end
      end
    end
  end

  describe "git_hook_check" do
    describe "author email check" do
      it 'returns true' do
        expect(access.git_hook_check(user, project, 'refs/heads/master', '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9', '570e7b2abdd848b95f2f578043fc23bd6f6fd24d')).to be_truthy
      end

      it 'returns false' do
        project.create_git_hook
        project.git_hook.update(commit_message_regex: "@only.com")
        expect(access.git_hook_check(user, project, 'refs/heads/master', '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9', '570e7b2abdd848b95f2f578043fc23bd6f6fd24d')).not_to be_allowed
      end

      it 'returns true for tags' do
        project.create_git_hook
        project.git_hook.update(commit_message_regex: "@only.com")
        expect(access.git_hook_check(user, project, 'refs/tags/v1', '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9', '570e7b2abdd848b95f2f578043fc23bd6f6fd24d')).to be_allowed
      end

      it 'allows githook for new branch with an old bad commit' do
        bad_commit = double("Commit", safe_message: 'Some change').as_null_object
        allow(bad_commit).to receive(:refs).and_return(['heads/master'])
        allow_any_instance_of(Repository).to receive(:commits_between).and_return([bad_commit])

        project.create_git_hook
        project.git_hook.update(commit_message_regex: "Change some files")

        # push to new branch, so use a blank old rev and new ref
        expect(access.git_hook_check(user, project, 'refs/heads/new-branch', Gitlab::Git::BLANK_SHA, '570e7b2abdd848b95f2f578043fc23bd6f6fd24d')).to be_allowed
      end
    end

    describe "member_check" do
      before do
        project.create_git_hook
        project.git_hook.update(member_check: true)
      end

      it 'returns false for non-member user' do
        expect(access.git_hook_check(user, project, 'refs/heads/master', '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9', '570e7b2abdd848b95f2f578043fc23bd6f6fd24d')).not_to be_allowed
      end

      it 'returns true if committer is a gitlab member' do
        create(:user, email: 'dmitriy.zaporozhets@gmail.com')
        expect(access.git_hook_check(user, project, 'refs/heads/master', '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9', '570e7b2abdd848b95f2f578043fc23bd6f6fd24d')).to be_allowed
      end
    end

    describe "file names check" do
      it 'returns false when filename is prohibited' do
        project.create_git_hook
        project.git_hook.update(file_name_regex: "jpg$")
        expect(access.git_hook_check(user, project, 'refs/heads/master', '913c66a37b4a45b9769037c55c2d238bd0942d2e', '33f3729a45c02fc67d00adb1b8bca394b0e761d9')).not_to be_allowed
      end

      it 'returns true if file name is allowed' do
        project.create_git_hook
        project.git_hook.update(file_name_regex: "exe$")
        expect(access.git_hook_check(user, project, 'refs/heads/master', '913c66a37b4a45b9769037c55c2d238bd0942d2e', '33f3729a45c02fc67d00adb1b8bca394b0e761d9')).to be_allowed
      end
    end

    describe "max file size check" do
      before do
        allow_any_instance_of(Gitlab::Git::Blob).to receive(:size).and_return(1.5.megabytes.to_i)
      end

      it "returns false when size is too large" do
        project.create_git_hook
        project.git_hook.update(max_file_size: 1)
        expect(access.git_hook_check(user, project, 'refs/heads/master', 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660', '913c66a37b4a45b9769037c55c2d238bd0942d2e')).not_to be_allowed
      end

      it "returns true when size is allowed" do
        project.create_git_hook
        project.git_hook.update(max_file_size: 2)
        expect(access.git_hook_check(user, project, 'refs/heads/master', 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660', '913c66a37b4a45b9769037c55c2d238bd0942d2e')).to be_allowed
      end

      it "returns true when size is nil" do
        allow_any_instance_of(Gitlab::Git::Blob).to receive(:size).and_return(nil)
        project.create_git_hook
        project.git_hook.update(max_file_size: 2)
        expect(access.git_hook_check(user, project, 'refs/heads/master', 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660', '913c66a37b4a45b9769037c55c2d238bd0942d2e')).to be_allowed
      end
    end
  end
end
