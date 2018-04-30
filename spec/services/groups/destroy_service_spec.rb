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

    context 'potential race conditions' do
      context "when the `GroupDestroyWorker` task runs immediately" do
        it "deletes the group" do
          # Commit the contents of this spec's transaction so far
          # so subsequent db connections can see it.
          #
          # DO NOT REMOVE THIS LINE, even if you see a WARNING with "No
          # transaction is currently in progress". Without this, this
          # spec will always be green, since the group created in setup
          # cannot be seen by any other connections / threads in this spec.
          Group.connection.commit_db_transaction

          group_record = run_with_new_database_connection do |conn|
            conn.execute("SELECT * FROM namespaces WHERE id = #{group.id}").first
          end

          expect(group_record).not_to be_nil

          # Execute the contents of `GroupDestroyWorker` in a separate thread, to
          # simulate data manipulation by the Sidekiq worker (different database
          # connection / transaction).
          expect(GroupDestroyWorker).to receive(:perform_async).and_wrap_original do |m, group_id, user_id|
            Thread.new { m[group_id, user_id] }.join(5)
          end

          # Kick off the initial group destroy in a new thread, so that
          # it doesn't share this spec's database transaction.
          Thread.new { described_class.new(group, user).async_execute }.join(5)

          group_record = run_with_new_database_connection do |conn|
            conn.execute("SELECT * FROM namespaces WHERE id = #{group.id}").first
          end

          expect(group_record).to be_nil
        end
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
