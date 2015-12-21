require 'spec_helper'

describe DestroyGroupService, services: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group) }
  let!(:project) { create(:project, namespace: group) }
  let!(:gitlab_shell) { Gitlab::Shell.new }
  let!(:remove_path) { group.path + "+#{group.id}+deleted" }

  context 'database records' do
    before do
      destroy_group(group, user)
    end

    it { expect(Group.all).not_to include(group) }
    it { expect(Project.all).not_to include(project) }
  end

  context 'file system' do
    context 'Sidekiq inline' do
      before do
        # Run sidekiq immediatly to check that renamed dir will be removed
        Sidekiq::Testing.inline! { destroy_group(group, user) }
      end

      it { expect(gitlab_shell.exists?(group.path)).to be_falsey }
      it { expect(gitlab_shell.exists?(remove_path)).to be_falsey }
    end

    context 'Sidekiq fake' do
      before do
        # Dont run sidekiq to check if renamed repository exists
        Sidekiq::Testing.fake! { destroy_group(group, user) }
      end

      it { expect(gitlab_shell.exists?(group.path)).to be_falsey }
      it { expect(gitlab_shell.exists?(remove_path)).to be_truthy }
    end
  end

  def destroy_group(group, user)
    DestroyGroupService.new(group, user).execute
  end
end
