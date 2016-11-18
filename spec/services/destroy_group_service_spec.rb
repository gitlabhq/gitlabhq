require 'spec_helper'

describe DestroyGroupService, services: true do
  include DatabaseConnectionHelpers

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
          Thread.new { DestroyGroupService.new(group, user).async_execute }.join(5)

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
end
