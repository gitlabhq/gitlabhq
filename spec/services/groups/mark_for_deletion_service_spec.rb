# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::MarkForDeletionService, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group, owners: user) }
  let(:original_group_path) { group.path }
  let(:original_group_name) { group.name }
  let(:service) { described_class.new(group, user) }

  subject(:result) { service.execute }

  context 'for a group that has not been marked for deletion' do
    context 'when rename_group_path_upon_deletion_scheduling feature flag is disabled' do
      before do
        stub_feature_flags(rename_group_path_upon_deletion_scheduling: false)
      end

      it 'does not rename group name' do
        expect { result }.not_to change {
          group.name
        }
      end

      it 'does not rename group path' do
        expect { result }.not_to change {
          group.path
        }
      end
    end

    context 'when a project under the group has a container image' do
      before do
        allow(group).to receive(:has_container_repository_including_subgroups?).and_return(true)
      end

      it 'does not rename group' do
        expect { result }.not_to change { group.path }
      end
    end

    it 'marks the group for deletion', :freeze_time do
      result

      expect(group.marked_for_deletion_on).to eq(Time.zone.today)
      expect(group.deleting_user).to eq(user)
    end

    it { is_expected.to be_success }

    it 'renames group name' do
      expect { result }.to change {
        group.name
      }.from(original_group_name).to("#{original_group_name}-deletion_scheduled-#{group.id}")
    end

    it 'renames group path' do
      expect { result }.to change {
        group.path
      }.from(original_group_path).to("#{original_group_path}-deletion_scheduled-#{group.id}")
    end

    it 'logs the event' do
      allow(Gitlab::AppLogger).to receive(:info).and_call_original
      expect(Gitlab::AppLogger).to receive(:info).with(
        "User #{user.id} marked group #{original_group_path}-deletion_scheduled-#{group.id} for deletion"
      )

      result
    end

    it 'sends notification' do
      expect_next_instance_of(NotificationService) do |service|
        expect(service).to receive(:group_scheduled_for_deletion).with(group)
      end

      result
    end

    shared_examples 'handles failure gracefully' do
      it 'returns error' do
        expect(result).to be_error
        expect(result.message).to eq('error message')
      end

      it 'does not send notification' do
        expect(NotificationService).not_to receive(:new)

        result
      end
    end

    context 'when group renaming fails' do
      before do
        allow_next_instance_of(Groups::UpdateService) do |group_update_service|
          allow(group_update_service).to receive(:execute).and_return(false)
          allow(group).to receive_message_chain(:errors, :full_messages)
            .and_return(['error message'])
        end
      end

      it_behaves_like 'handles failure gracefully'
    end

    context 'when deletion schedule creation fails' do
      before do
        group_deletion_schedule = instance_double(GroupDeletionSchedule)
        allow(group).to receive(:build_deletion_schedule).and_return(group_deletion_schedule)
        allow(group_deletion_schedule).to receive(:save).and_return(false)
        allow(group_deletion_schedule).to receive_message_chain(:errors, :full_messages)
          .and_return(['error message'])
      end

      it_behaves_like 'handles failure gracefully'
    end
  end

  context 'when group is already marked for deletion' do
    let(:deletion_date) { 3.days.ago }
    let(:group) do
      create(:group_with_deletion_schedule,
        marked_for_deletion_on: deletion_date,
        owners: user,
        deleting_user: user)
    end

    it 'does not change the attributes associated with delayed deletion' do
      expect(result).to be_error
      expect(group).to be_self_deletion_scheduled
      expect(group.self_deletion_scheduled_deletion_created_on).to eq(deletion_date.to_date)
      expect(group.deleting_user).to eq(user)
    end

    it 'does not send notification' do
      # eager-load service to avoid false positive NotificationService.new calls
      service

      expect(NotificationService).not_to receive(:new)
      expect(result).to be_error
    end

    it 'returns error' do
      expect(result).to be_error
      expect(result.message).to eq('Group has been already marked for deletion')
    end
  end

  context 'with a user that cannot admin the group' do
    let(:group) { build(:group) }

    it 'does not mark the group for deletion' do
      expect(result).to be_error
      expect(group).not_to be_self_deletion_scheduled
    end

    it 'returns error' do
      expect(result).to be_error
      expect(result.message).to eq('You are not authorized to perform this action')
    end
  end
end
