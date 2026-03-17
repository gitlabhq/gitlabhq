# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TransferWorker, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be(:new_namespace) { create(:group) }

  let(:worker) { described_class.new }
  let(:project_namespace) { project.project_namespace }

  describe '#perform', :clean_gitlab_redis_shared_state do
    subject(:perform) { worker.perform(project.id, new_namespace.id, user.id) }

    context 'when all records exist' do
      before_all do
        project.add_owner(user)
        new_namespace.add_owner(user)
      end

      it 'transfers the project to the new namespace' do
        perform

        expect(project.reload.namespace).to eq(new_namespace)
        expect(project_namespace.reload).to be_ancestor_inherited
      end

      context 'when TransferService returns false' do
        it 'cancels the transfer' do
          expect_next_instance_of(::Projects::TransferService) do |service|
            expect(service).to receive(:execute).with(new_namespace).and_return(false)
          end

          perform

          expect(project_namespace.reload).not_to be_transfer_in_progress
        end
      end

      context 'when TransferService raises an error' do
        it 'cancels the transfer, logs the error, and re-raises' do
          expect_next_instance_of(::Projects::TransferService) do |service|
            expect(service).to receive(:execute).and_raise(StandardError, 'something went wrong')
          end

          allow(Gitlab::AppLogger).to receive(:error)

          expect { perform }.to raise_error(StandardError, 'something went wrong')
          expect(project_namespace.reload).not_to be_transfer_in_progress
          expect(Gitlab::AppLogger).to have_received(:error).with(hash_including(
            message: 'Projects::TransferWorker failed',
            project_id: project.id,
            new_namespace_id: new_namespace.id,
            error: 'something went wrong'
          ))
        end
      end

      context 'when TransferService raises and cancel_transfer! also raises' do
        it 'logs the cancel error separately and re-raises the original error' do
          expect_next_instance_of(::Projects::TransferService) do |service|
            expect(service).to receive(:execute).and_raise(StandardError, 'transfer failed')
          end

          allow_next_found_instance_of(Namespaces::ProjectNamespace) do |ns|
            allow(ns).to receive(:transfer_in_progress?).and_return(true)
            allow(ns).to receive(:cancel_transfer!).and_raise(StandardError, 'cancel failed')
          end

          allow(Gitlab::AppLogger).to receive(:error)

          expect { perform }.to raise_error(StandardError, 'transfer failed')

          expect(Gitlab::AppLogger).to have_received(:error).with(hash_including(
            message: 'Projects::TransferWorker failed to cancel transfer state',
            project_id: project.id,
            error: 'cancel failed'
          ))
          expect(Gitlab::AppLogger).to have_received(:error).with(hash_including(
            message: 'Projects::TransferWorker failed',
            project_id: project.id,
            new_namespace_id: new_namespace.id,
            error: 'transfer failed'
          ))
        end
      end

      context 'when an error occurs before the transfer is started' do
        before do
          project_namespace.update_column(:state, Namespace.states[:maintenance])
        end

        it 'does not call cancel_transfer! and re-raises' do
          allow(Gitlab::AppLogger).to receive(:error)

          expect { perform }.to raise_error(StateMachines::InvalidTransition)
          expect(project_namespace.reload).not_to be_transfer_in_progress
          expect(Gitlab::AppLogger).to have_received(:error).with(hash_including(
            message: 'Projects::TransferWorker failed',
            project_id: project.id,
            new_namespace_id: new_namespace.id
          ))
        end
      end

      context 'when exclusive lease is already set' do
        let(:lease_key) { "projects_transfer_worker:#{project.id}" }
        let(:exclusive_lease) { Gitlab::ExclusiveLease.new(lease_key, uuid: uuid, timeout: 1.minute) }
        let(:uuid) { 'other_worker_jid' }

        it 'does not call the transfer service and does not cancel the transfer state' do
          project_namespace.start_transfer!(transition_user: user)

          expect(exclusive_lease.try_obtain).to eq(uuid)
          expect(::Projects::TransferService).not_to receive(:new)

          perform

          expect(project_namespace.reload).to be_transfer_in_progress
        end

        it 'does nothing if transfer is not in progress' do
          expect(exclusive_lease.try_obtain).to eq(uuid)
          expect(::Projects::TransferService).not_to receive(:new)

          expect { perform }.not_to raise_error
        end

        context 'when exclusive lease was taken by the current worker (Sidekiq interrupt)' do
          let(:uuid) { 'existing_worker_jid' }

          before do
            allow(worker).to receive(:jid).and_return(uuid)
          end

          it 'cancels the stale lock so a subsequent retry can proceed' do
            expect(exclusive_lease.try_obtain).to eq(worker.jid)
            expect(::Projects::TransferService).not_to receive(:new)

            perform

            # verify the lease was released by checking it can be re-obtained
            new_lease = Gitlab::ExclusiveLease.new(lease_key, uuid: 'new_uuid', timeout: 1.minute)
            expect(new_lease.try_obtain).to eq('new_uuid')
          end
        end
      end
    end

    context 'when project does not exist' do
      subject(:perform) { worker.perform(non_existing_record_id, new_namespace.id, user.id) }

      it 'returns early without calling the transfer service' do
        expect(::Projects::TransferService).not_to receive(:new)

        expect { perform }.not_to raise_error
      end
    end

    context 'when user does not exist' do
      subject(:perform) { worker.perform(project.id, new_namespace.id, non_existing_record_id) }

      it 'returns early without calling the transfer service' do
        expect(::Projects::TransferService).not_to receive(:new)

        expect { perform }.not_to raise_error
      end
    end

    context 'when new namespace does not exist' do
      subject(:perform) { worker.perform(project.id, non_existing_record_id, user.id) }

      it 'returns early without calling the transfer service' do
        expect(::Projects::TransferService).not_to receive(:new)

        expect { perform }.not_to raise_error
      end
    end
  end
end
