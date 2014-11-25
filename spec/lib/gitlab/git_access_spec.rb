require 'spec_helper'

describe Gitlab::GitAccess do
  let(:access) { Gitlab::GitAccess.new }
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  describe 'download_access_check' do
    describe 'master permissions' do
      before { project.team << [user, :master] }

      context 'pull code' do
        subject { access.download_access_check(user, project) }

        it { subject.allowed?.should be_true }
      end
    end

    describe 'guest permissions' do
      before { project.team << [user, :guest] }

      context 'pull code' do
        subject { access.download_access_check(user, project) }

        it { subject.allowed?.should be_false }
      end
    end

    describe 'blocked user' do
      before do
        project.team << [user, :master]
        user.block
      end

      context 'pull code' do
        subject { access.download_access_check(user, project) }

        it { subject.allowed?.should be_false }
      end
    end

    describe 'without acccess to project' do
      context 'pull code' do
        subject { access.download_access_check(user, project) }

        it { subject.allowed?.should be_false }
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

    permissions_matrix.keys.each do |role|
      describe "#{role} access" do
        before { protect_feature_branch }
        before { project.team << [user, role] }

        permissions_matrix[role].each do |action, allowed|
          context action do
            subject { access.push_access_check(user, project, changes[action]) }

            it { subject.allowed?.should allowed ? be_true : be_false }
          end
        end
      end
    end
  end

  describe "pass_git_hooks?" do
    describe "author email check" do
      it 'returns true' do
        access.pass_git_hooks?(user, project, 'refs/heads/master', '6f6d7e7ed', '570e7b2ab').should be_true
      end

      it 'returns false' do
        project.create_git_hook
        project.git_hook.update(commit_message_regex: "@only.com")
        access.pass_git_hooks?(user, project, 'refs/heads/master', '6f6d7e7ed', '570e7b2ab').allowed?.should be_false
      end
    end

    describe "member_check" do
      before do
        project.create_git_hook
        project.git_hook.update(member_check: true)
      end

      it 'returns false for non-member user' do
        access.pass_git_hooks?(user, project, 'refs/heads/master', '6f6d7e7ed', '570e7b2ab').allowed?.should be_false
      end

      it 'returns true if committer is a gitlab member' do
        create(:user, email: 'dmitriy.zaporozhets@gmail.com')
        access.pass_git_hooks?(user, project, 'refs/heads/master', '6f6d7e7ed', '570e7b2ab').allowed?.should be_true
      end
    end

    describe "file names check" do
      it 'returns false when filename is prohibited' do
        project.create_git_hook
        project.git_hook.update(file_name_regex: "jpg$")
        access.pass_git_hooks?(user, project, 'refs/heads/master', '913c66a37', '33f3729a4').allowed?.should be_false
      end

      it 'returns true if file name is allowed' do
        project.create_git_hook
        project.git_hook.update(file_name_regex: "exe$")
        access.pass_git_hooks?(user, project, 'refs/heads/master', '913c66a37', '33f3729a4').allowed?.should be_true
      end
    end
  end
end
