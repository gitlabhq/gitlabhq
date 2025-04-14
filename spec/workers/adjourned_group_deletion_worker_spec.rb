# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AdjournedGroupDeletionWorker, feature_category: :groups_and_projects do
  describe "#perform" do
    subject(:worker) { described_class.new }

    let(:user) { create(:user) }
    let!(:group_not_marked_for_deletion) { create(:group) }
    let!(:parent_group) { create(:group) }
    let!(:group_marked_for_deletion) do
      create(:group_with_deletion_schedule,
        parent: parent_group,
        marked_for_deletion_on: 15.days.ago,
        deleting_user: user)
    end

    let!(:group_marked_for_deletion_for_later) do
      create(:group_with_deletion_schedule, marked_for_deletion_on: 2.days.ago, deleting_user: user)
    end

    before do
      stub_application_setting(deletion_adjourned_period: 14)
      stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
    end

    context 'when deleting user has access to delete the group' do
      before do
        group_not_marked_for_deletion.add_owner(user)
        group_marked_for_deletion.add_owner(user)
        group_marked_for_deletion_for_later.add_owner(user)
      end

      it 'only schedules to delete groups marked for deletion on or before the specified `deletion_adjourned_period`' do
        expect(GroupDestroyWorker).to receive(:perform_in).with(0, group_marked_for_deletion.id, user.id)

        worker.perform
      end

      it 'does not schedule to delete a group not marked for deletion' do
        expect(GroupDestroyWorker).not_to receive(:perform_in).with(0, group_not_marked_for_deletion.id, user.id)

        worker.perform
      end

      it 'does not schedule to delete a group marked for deletion after the specified `deletion_adjourned_period`' do
        expect(GroupDestroyWorker).not_to receive(:perform_in).with(0, group_marked_for_deletion_for_later.id, user.id)

        worker.perform
      end

      it 'schedules groups 20 seconds apart' do
        group_marked_for_deletion_2 = create(
          :group_with_deletion_schedule,
          marked_for_deletion_on: 14.days.ago,
          deleting_user: user,
          owners: user
        )

        expect(GroupDestroyWorker).to receive(:perform_in).with(0, group_marked_for_deletion.id, user.id)
        expect(GroupDestroyWorker).to receive(:perform_in).with(20, group_marked_for_deletion_2.id, user.id)

        worker.perform
      end
    end

    context 'with direct and indirect accesses to group', :sidekiq_inline do
      shared_examples 'destroys the group' do
        specify do
          worker.perform

          expect(Group.exists?(group_marked_for_deletion.id)).to be_falsey
        end
      end

      context 'when user is a direct owner' do
        before do
          group_marked_for_deletion.add_owner(user)
        end

        it_behaves_like 'destroys the group'
      end

      context 'when user is an inherited owner' do
        before do
          parent_group.add_owner(user)
        end

        it_behaves_like 'destroys the group'
      end

      context 'when user is an owner through group sharing' do
        before do
          invited_group = create(:group, owners: user)
          create(:group_group_link, :owner, shared_group: group_marked_for_deletion, shared_with_group: invited_group)
        end

        it_behaves_like 'destroys the group'
      end

      context 'when user is an owner through parent group sharing' do
        before do
          invited_group = create(:group, owners: user)
          create(:group_group_link, :owner, shared_group: parent_group, shared_with_group: invited_group)
        end

        it_behaves_like 'destroys the group'
      end

      context 'when an admin deletes the group', :enable_admin_mode do
        let_it_be(:user) { create(:admin) }

        before do
          group_marked_for_deletion.deletion_schedule.update!(deleting_user: user)
        end

        it_behaves_like 'destroys the group'
      end
    end

    context 'when the deleting user does not have access to delete the group', :sidekiq_inline, :enable_admin_mode do
      it 'restores the group' do
        worker.perform

        expect(group_marked_for_deletion.reload.marked_for_deletion?).to be_falsey
      end
    end
  end
end
