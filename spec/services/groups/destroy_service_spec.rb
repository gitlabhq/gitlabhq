require 'spec_helper'

describe Groups::DestroyService do
  include DatabaseConnectionHelpers

  let!(:user)         { create(:user) }
  let!(:group)        { create(:group) }
  let!(:nested_group) { create(:group, parent: group) }
  let!(:project)      { create(:project, :legacy_storage, namespace: group) }
  let!(:notification_setting) { create(:notification_setting, source: group)}
  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:remove_path)  { group.path + "+#{group.id}+deleted" }

  before do
    group.add_user(user, Gitlab::Access::OWNER)
  end

  def destroy_group(group, user, async)
    if async
      Groups::DestroyService.new(group, user).async_execute
    else
      Groups::DestroyService.new(group, user).execute
    end
  end

  shared_examples 'group destruction' do |async|
    context 'database records' do
      before do
        destroy_group(group, user, async)
      end

      it { expect(Group.unscoped.all).not_to include(group) }
      it { expect(Group.unscoped.all).not_to include(nested_group) }
      it { expect(Project.unscoped.all).not_to include(project) }
      it { expect(NotificationSetting.unscoped.all).not_to include(notification_setting) }
    end

    context 'mattermost team' do
      let!(:chat_team) { create(:chat_team, namespace: group) }

      it 'destroys the team too' do
        expect_any_instance_of(Mattermost::Team).to receive(:destroy)

        destroy_group(group, user, async)
      end
    end

    context 'file system' do
      context 'Sidekiq inline' do
        before do
          # Run sidekiq immediately to check that renamed dir will be removed
          Sidekiq::Testing.inline! { destroy_group(group, user, async) }
        end

        it 'verifies that paths have been deleted' do
          expect(gitlab_shell.exists?(project.repository_storage, group.path)).to be_falsey
          expect(gitlab_shell.exists?(project.repository_storage, remove_path)).to be_falsey
        end
      end
    end
  end

  describe 'asynchronous delete' do
    it_behaves_like 'group destruction', true

    context 'Sidekiq fake' do
      before do
        # Don't run Sidekiq to verify that group and projects are not actually destroyed
        Sidekiq::Testing.fake! { destroy_group(group, user, true) }
      end

      after do
        # Clean up stale directories
        gitlab_shell.rm_namespace(project.repository_storage, group.path)
        gitlab_shell.rm_namespace(project.repository_storage, remove_path)
      end

      it 'verifies original paths and projects still exist' do
        expect(gitlab_shell.exists?(project.repository_storage, group.path)).to be_truthy
        expect(gitlab_shell.exists?(project.repository_storage, remove_path)).to be_falsey
        expect(Project.unscoped.count).to eq(1)
        expect(Group.unscoped.count).to eq(2)
      end
    end
  end

  describe 'synchronous delete' do
    it_behaves_like 'group destruction', false
  end

  context 'projects in pending_delete' do
    before do
      project.pending_delete = true
      project.save
    end

    it_behaves_like 'group destruction', false
  end

  describe 'repository removal' do
    before do
      destroy_group(group, user, false)
    end

    context 'legacy storage' do
      let!(:project) { create(:project, :legacy_storage, :empty_repo, namespace: group) }

      it 'removes repository' do
        expect(gitlab_shell.exists?(project.repository_storage, "#{project.disk_path}.git")).to be_falsey
      end
    end

    context 'hashed storage' do
      let!(:project) { create(:project, :empty_repo, namespace: group) }

      it 'removes repository' do
        expect(gitlab_shell.exists?(project.repository_storage, "#{project.disk_path}.git")).to be_falsey
      end
    end
  end
end
