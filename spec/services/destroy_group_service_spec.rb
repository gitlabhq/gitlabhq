require 'spec_helper'

describe DestroyGroupService, services: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group) }
  let!(:project) { create(:project, namespace: group) }
  let!(:gitlab_shell) { Gitlab::Shell.new }
  let!(:remove_path) { group.path + "+#{group.id}+deleted" }

  shared_examples 'group destruction' do |async|
    context 'database records' do
      before do
        destroy_group(group, user, async)
      end

      it { expect(Group.all).not_to include(group) }
      it { expect(Project.all).not_to include(project) }
    end

    context 'file system' do
      context 'Sidekiq inline' do
        before do
          # Run sidekiq immediatly to check that renamed dir will be removed
          Sidekiq::Testing.inline! { destroy_group(group, user, async) }
        end

        it { expect(gitlab_shell.exists?(project.repository_storage_path, group.path)).to be_falsey }
        it { expect(gitlab_shell.exists?(project.repository_storage_path, remove_path)).to be_falsey }
      end

      context 'Sidekiq fake' do
        before do
          # Dont run sidekiq to check if renamed repository exists
          Sidekiq::Testing.fake! { destroy_group(group, user, async) }
        end

        it { expect(gitlab_shell.exists?(project.repository_storage_path, group.path)).to be_falsey }
        it { expect(gitlab_shell.exists?(project.repository_storage_path, remove_path)).to be_truthy }
      end
    end

    def destroy_group(group, user, async)
      if async
        DestroyGroupService.new(group, user).async_execute
      else
        DestroyGroupService.new(group, user).execute
      end
    end
  end

  describe 'asynchronous delete' do
    it_behaves_like 'group destruction', true
  end

  describe 'synchronous delete' do
    it_behaves_like 'group destruction', false
  end
end
