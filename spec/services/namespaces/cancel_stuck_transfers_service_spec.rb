# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::CancelStuckTransfersService, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }

  subject(:service) { described_class.new }

  describe '#execute' do
    context 'when a group is stuck in transfer_in_progress' do
      let_it_be_with_reload(:group) { create(:group) }

      before_all do
        group.add_owner(user)
      end

      before do
        freeze_time do
          group.schedule_transfer!(transition_user: user)
          group.start_transfer!(transition_user: user)
          group.update_column(:updated_at, 5.hours.ago)
        end
      end

      it 'cancels the stuck transfer' do
        expect { service.execute }.to change { group.reload.state }
          .from('transfer_in_progress').to('ancestor_inherited')
      end

      it 'returns the count of cancelled transfers' do
        expect(service.execute).to eq(1)
      end

      it 'logs a warning with structured metadata' do
        expect(Gitlab::AppLogger).to receive(:warn).with(hash_including(
          message: 'Cancelling stuck transfer - no active worker lease found',
          namespace_id: group.id,
          namespace_type: 'Group',
          state: 'transfer_in_progress',
          stuck_duration_seconds: a_kind_of(Integer)
        ))

        service.execute
      end

      context 'when an active worker lease exists' do
        before do
          Gitlab::ExclusiveLease.new(
            Namespaces::Groups::TransferWorker.lease_key(group.id), timeout: 30.minutes
          ).try_obtain
        end

        it 'does not cancel the transfer' do
          expect { service.execute }.not_to change { group.reload.state }
        end

        it 'returns zero cancelled' do
          expect(service.execute).to eq(0)
        end
      end
    end

    context 'when a group is stuck in transfer_scheduled' do
      let_it_be_with_reload(:group) { create(:group) }

      before_all do
        group.add_owner(user)
      end

      before do
        group.schedule_transfer!(transition_user: user)
        group.update_column(:updated_at, 2.hours.ago)
      end

      it 'cancels the stuck scheduled transfer' do
        expect { service.execute }.to change { group.reload.state }.from('transfer_scheduled').to('ancestor_inherited')
      end

      it 'returns the count of cancelled transfers' do
        expect(service.execute).to eq(1)
      end

      context 'when updated_at is within the scheduled timeout' do
        before do
          group.update_column(:updated_at, 30.minutes.ago)
        end

        it 'does not cancel the transfer' do
          expect { service.execute }.not_to change { group.reload.state }
        end
      end
    end

    context 'when a project namespace is stuck in transfer_in_progress' do
      let_it_be(:project) { create(:project) }
      let_it_be_with_reload(:project_namespace) { project.project_namespace }

      before_all do
        project.add_owner(user)
      end

      before do
        project_namespace.schedule_transfer!(transition_user: user)
        project_namespace.start_transfer!(transition_user: user)
        project_namespace.update_column(:updated_at, 5.hours.ago)
      end

      it 'cancels the stuck transfer' do
        expect { service.execute }.to change { project_namespace.reload.state }
          .from('transfer_in_progress').to('ancestor_inherited')
      end

      it 'checks the correct worker lease key' do
        expect(Gitlab::ExclusiveLease).to receive(:get_uuid)
          .with(Projects::TransferWorker.lease_key(project.id))
          .and_return(nil)

        service.execute
      end

      context 'when an active worker lease exists' do
        before do
          Gitlab::ExclusiveLease.new(
            Projects::TransferWorker.lease_key(project.id), timeout: 30.minutes
          ).try_obtain
        end

        it 'does not cancel the transfer' do
          expect { service.execute }.not_to change { project_namespace.reload.state }
        end
      end
    end

    context 'when there are no stuck transfers' do
      it 'returns zero' do
        expect(service.execute).to eq(0)
      end

      it 'logs the completion' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          message: 'CancelStuckTransfersService completed',
          total_cancelled: 0
        )

        service.execute
      end
    end

    context 'when cancel_transfer! raises an error for one namespace' do
      let_it_be_with_reload(:group1) { create(:group) }
      let_it_be_with_reload(:group2) { create(:group) }

      before do
        [group1, group2].each do |g|
          g.add_owner(user)
          g.schedule_transfer!(transition_user: user)
          g.start_transfer!(transition_user: user)
          g.update_column(:updated_at, 5.hours.ago)
        end

        allow(service).to receive(:cancel_transfer).and_call_original
        allow(service).to receive(:cancel_transfer)
          .with(an_object_having_attributes(id: group1.id), 'transfer_in_progress')
          .and_raise(StandardError, 'state machine error')
      end

      it 'continues processing remaining namespaces and logs the error', :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:error).with(hash_including(
          message: 'CancelStuckTransfersService failed to cancel stuck transfer',
          namespace_id: group1.id
        ))

        result = service.execute
        expect(result).to eq(1)
        expect(group2.reload.state).to eq('ancestor_inherited')
      end
    end

    context 'when there are mixed stuck states' do
      let_it_be_with_reload(:in_progress_group) { create(:group) }
      let_it_be_with_reload(:scheduled_group) { create(:group) }

      before do
        [in_progress_group, scheduled_group].each { |g| g.add_owner(user) }

        in_progress_group.schedule_transfer!(transition_user: user)
        in_progress_group.start_transfer!(transition_user: user)
        in_progress_group.update_column(:updated_at, 5.hours.ago)

        scheduled_group.schedule_transfer!(transition_user: user)
        scheduled_group.update_column(:updated_at, 2.hours.ago)
      end

      it 'cancels both stuck transfers', :aggregate_failures do
        expect(service.execute).to eq(2)
        expect(in_progress_group.reload.state).to eq('ancestor_inherited')
        expect(scheduled_group.reload.state).to eq('ancestor_inherited')
      end
    end
  end
end
