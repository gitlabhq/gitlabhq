require 'spec_helper'

describe Gitlab::GitAccess do
  let(:access) { Gitlab::GitAccess.new }
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  describe 'download_allowed?' do
    describe 'master permissions' do
      before { project.team << [user, :master] }

      context 'pull code' do
        subject { access.download_allowed?(user, project) }

        it { should be_true }
      end
    end

    describe 'guest permissions' do
      before { project.team << [user, :guest] }

      context 'pull code' do
        subject { access.download_allowed?(user, project) }

        it { should be_false }
      end
    end

    describe 'blocked user' do
      before do
        project.team << [user, :master]
        user.block
      end

      context 'pull code' do
        subject { access.download_allowed?(user, project) }

        it { should be_false }
      end
    end

    describe 'without acccess to project' do
      context 'pull code' do
        subject { access.download_allowed?(user, project) }

        it { should be_false }
      end
    end
  end

  describe 'push_allowed?' do
    describe 'master permissions' do
      before { project.team << [user, :master] }

      context 'push to new branch' do
        subject { access.push_allowed?(user, project, new_branch_changes) }

        it { should be_true }
      end

      context 'push to master branch' do
        subject { access.push_allowed?(user, project, master_changes) }

        it { should be_true }
      end

      context 'push to protected branch' do
        before { protect_master }
        subject { access.push_allowed?(user, project, master_changes) }

        it { should be_true }
      end

      context 'remove protected branch' do
        before { protect_master }
        subject { access.push_allowed?(user, project, remove_master_changes) }

        it { should be_false }
      end

      context 'push to existing tag' do
        subject { access.push_allowed?(user, project, tag_changes) }

        it { should be_true }
      end

      context 'push new tag' do
        subject { access.push_allowed?(user, project, new_tag_changes) }

        it { should be_true }
      end

      context 'push new tag and protected branch' do
        before { protect_master }
        subject { access.push_allowed?(user, project, [new_tag_changes, master_changes]) }

        it { should be_true }
      end
    end

    describe 'developer permissions' do
      before { project.team << [user, :developer] }

      context 'push to new branch' do
        subject { access.push_allowed?(user, project, new_branch_changes) }

        it { should be_true }
      end

      context 'push to master branch' do
        subject { access.push_allowed?(user, project, master_changes) }

        it { should be_true }
      end

      context 'push to protected branch' do
        before { protect_master }
        subject { access.push_allowed?(user, project, master_changes) }

        it { should be_false }
      end

      context 'remove protected branch' do
        before { protect_master }
        subject { access.push_allowed?(user, project, remove_master_changes) }

        it { should be_false }
      end

      context 'push to existing tag' do
        subject { access.push_allowed?(user, project, tag_changes) }

        it { should be_false }
      end

      context 'push new tag' do
        subject { access.push_allowed?(user, project, new_tag_changes) }

        it { should be_true }
      end

      context 'push new tag and protected branch' do
        before { protect_master }
        subject { access.push_allowed?(user, project, [new_tag_changes, master_changes]) }

        it { should be_false }
      end
    end
  end

  describe 'forced_push?' do
    subject { access.forced_push?(project, '111111', '222222') }

    it { should be_false }
  end

  def new_branch_changes
    '000000000 570e7b2ab refs/heads/wow'
  end

  def master_changes
    '6f6d7e7ed 570e7b2ab refs/heads/master'
  end

  def remove_master_changes
    '570e7b2ab 000000000 refs/heads/master'
  end

  def tag_changes
    '6f6d7e7ed 570e7b2ab refs/tags/v1.0.0'
  end

  def new_tag_changes
    '000000000 570e7b2ab refs/tags/v7.8.9'
  end

  def protect_master
    create(:protected_branch, name: 'master', project: project)
  end
end
