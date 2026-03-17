# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Groups::TransferWorker, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be(:new_parent_group) { create(:group) }

  let(:worker) { described_class.new }

  describe '#perform', :clean_gitlab_redis_shared_state do
    subject(:perform) { worker.perform(group.id, new_parent_group.id, user.id) }

    context 'when all records exist' do
      before_all do
        group.add_owner(user)
        new_parent_group.add_owner(user)
      end

      it 'transfers the group to the new parent and completes the transfer' do
        perform

        expect(group.reload).to have_attributes(parent: new_parent_group, state: 'ancestor_inherited')
      end

      context 'when TransferService returns false' do
        it 'cancels the transfer' do
          expect_next_instance_of(::Groups::TransferService, group, user) do |service|
            expect(service).to receive(:execute).with(new_parent_group).and_return(false)
          end

          perform

          expect(group.reload.state).to eq('ancestor_inherited')
        end
      end

      context 'when TransferService raises an error' do
        it 'cancels the transfer, logs the error, and re-raises' do
          expect_next_instance_of(::Groups::TransferService, group, user) do |service|
            expect(service).to receive(:execute).and_raise(StandardError, 'something went wrong')
          end

          allow(Gitlab::AppLogger).to receive(:error)

          expect { perform }.to raise_error(StandardError, 'something went wrong')

          expect(group.reload.state).to eq('ancestor_inherited')
          expect(Gitlab::AppLogger).to have_received(:error).with(hash_including(
            message: 'Namespaces::Groups::TransferWorker failed',
            group_id: group.id,
            new_parent_group_id: new_parent_group.id,
            error: 'something went wrong'
          ))
        end
      end

      context 'when TransferService raises and cancel_transfer! also raises' do
        it 'logs the cancel error separately and re-raises the original error' do
          expect_next_instance_of(::Groups::TransferService, group, user) do |service|
            expect(service).to receive(:execute).and_raise(StandardError, 'transfer failed')
          end

          allow_next_found_instance_of(Group) do |g|
            allow(g).to receive(:transfer_in_progress?).and_return(true)
            allow(g).to receive(:cancel_transfer!).and_raise(StandardError, 'cancel failed')
          end

          allow(Gitlab::AppLogger).to receive(:error)

          expect { perform }.to raise_error(StandardError, 'transfer failed')

          expect(Gitlab::AppLogger).to have_received(:error).with(hash_including(
            message: 'Namespaces::Groups::TransferWorker failed to cancel transfer state',
            error: 'cancel failed'
          ))
          expect(Gitlab::AppLogger).to have_received(:error).with(hash_including(
            message: 'Namespaces::Groups::TransferWorker failed',
            error: 'transfer failed'
          ))
        end
      end

      context 'when start_transfer! raises an error' do
        it 'logs the error and re-raises without calling cancel_transfer!' do
          group.update_column(:state, Group.states[:creation_in_progress])

          allow(Gitlab::AppLogger).to receive(:error)

          expect { perform }.to raise_error(StateMachines::InvalidTransition)

          expect(Gitlab::AppLogger).to have_received(:error).with(hash_including(
            message: 'Namespaces::Groups::TransferWorker failed',
            group_id: group.id,
            new_parent_group_id: new_parent_group.id
          ))

          expect(group.reload.state).to eq('creation_in_progress')
        end
      end

      context 'when exclusive lease is already set' do
        let(:lease_key) { "namespaces_groups_transfer_worker:#{group.id}" }
        let(:exclusive_lease) { Gitlab::ExclusiveLease.new(lease_key, uuid: uuid, timeout: 1.minute) }
        let(:uuid) { 'other_worker_jid' }

        it 'does not call the transfer service and leaves state unchanged when another worker holds the lease' do
          group.start_transfer!(transition_user: user)

          expect(exclusive_lease.try_obtain).to eq(uuid)
          expect(::Groups::TransferService).not_to receive(:new)

          perform

          expect(group.reload).to be_transfer_in_progress
        end

        it 'does nothing if transfer is not in progress' do
          expect(exclusive_lease.try_obtain).to eq(uuid)
          expect(::Groups::TransferService).not_to receive(:new)

          expect { perform }.not_to raise_error
        end

        context 'when exclusive lease was taken by the current worker (Sidekiq interrupt)' do
          let(:uuid) { 'existing_worker_jid' }

          before do
            allow(worker).to receive(:jid).and_return(uuid)
          end

          it 'cancels the stale lock so a subsequent retry can proceed' do
            expect(exclusive_lease.try_obtain).to eq(worker.jid)
            expect(::Groups::TransferService).not_to receive(:new)

            perform

            # verify the lease was released by checking it can be re-obtained
            new_lease = Gitlab::ExclusiveLease.new(lease_key, uuid: 'new_uuid', timeout: 1.minute)
            expect(new_lease.try_obtain).to eq('new_uuid')
          end
        end
      end
    end

    context 'when transferring to root (no parent group)' do
      subject(:perform) { worker.perform(group.id, nil, user.id) }

      it 'transfers the group to root and completes the transfer' do
        perform

        expect(group.reload).to have_attributes(parent: nil, state: 'ancestor_inherited')
      end

      context 'when TransferService raises an error' do
        it 'logs error with nil new_parent_group_id and re-raises' do
          expect_next_instance_of(::Groups::TransferService, group, user) do |service|
            expect(service).to receive(:execute).with(nil).and_raise(StandardError, 'transfer failed')
          end

          allow(Gitlab::AppLogger).to receive(:error)

          expect { perform }.to raise_error(StandardError, 'transfer failed')

          expect(Gitlab::AppLogger).to have_received(:error).with(hash_including(
            message: 'Namespaces::Groups::TransferWorker failed',
            group_id: group.id,
            new_parent_group_id: nil,
            error: 'transfer failed'
          ))
        end
      end
    end

    context 'when group does not exist' do
      subject(:perform) { worker.perform(non_existing_record_id, new_parent_group.id, user.id) }

      it 'does not call the transfer service and does not raise' do
        expect(::Groups::TransferService).not_to receive(:new)
        expect { perform }.not_to raise_error
      end
    end

    context 'when user does not exist' do
      subject(:perform) { worker.perform(group.id, new_parent_group.id, non_existing_record_id) }

      it 'does not call the transfer service and does not raise' do
        expect(::Groups::TransferService).not_to receive(:new)
        expect { perform }.not_to raise_error
      end
    end
  end
end
