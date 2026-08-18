# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::TransferWorkerHelper, feature_category: :groups_and_projects do
  let(:worker_class) do
    Class.new do
      include Namespaces::TransferWorkerHelper

      public :cancel_stale_transfer_state
      public :create_transfer_failure_todo
    end
  end

  let(:worker) { worker_class.new }

  describe '#cancel_stale_transfer_state' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:group) { create(:group) }

    context 'when namespace is in transfer_in_progress state' do
      before do
        group.schedule_transfer!(transition_user: user)
        group.start_transfer!(transition_user: user)
      end

      it 'cancels the state and logs a warning with the standardised payload' do
        allow(Gitlab::AppLogger).to receive(:warn)

        worker.cancel_stale_transfer_state(group, group_id: group.id)

        expect(group.reload).to be_ancestor_inherited
        expect(Gitlab::AppLogger).to have_received(:warn).with(hash_including(
          'message' => 'Cancelling stale transfer state',
          'group_id' => group.id,
          'gl_namespace_id' => group.id,
          'namespace_type' => 'group',
          'correlation_id' => kind_of(String)
        ))
      end
    end

    context 'when namespace is in transfer_scheduled state' do
      before do
        group.schedule_transfer!(transition_user: user)
      end

      it 'does not cancel the state', :aggregate_failures do
        expect(group).not_to receive(:cancel_transfer!)

        worker.cancel_stale_transfer_state(group, group_id: group.id)

        expect(group.reload).to be_transfer_scheduled
      end
    end

    context 'when namespace is in a normal state' do
      it 'does nothing' do
        expect(group).not_to receive(:cancel_transfer!)

        worker.cancel_stale_transfer_state(group, group_id: group.id)
      end
    end
  end

  describe '#create_transfer_failure_todo' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let(:todo_service) { instance_double(TodoService) }

    before do
      allow(TodoService).to receive(:new).and_return(todo_service)
    end

    it 'delegates transfer failure todo creation to TodoService' do
      expect(todo_service).to receive(:transfer_failed).with(group, user)

      worker.create_transfer_failure_todo(group, user, worker_name: 'TransferWorker', group_id: group.id)
    end

    it 'logs an error and does not raise when TodoService fails' do
      allow(todo_service).to receive(:transfer_failed).with(group, user).and_raise(StandardError, 'service failed')
      allow(Gitlab::AppLogger).to receive(:error)

      expect do
        worker.create_transfer_failure_todo(group, user, worker_name: 'TransferWorker', group_id: group.id)
      end.not_to raise_error

      expect(Gitlab::AppLogger).to have_received(:error).with(hash_including(
        message: 'TransferWorker failed to create transfer failure todo',
        Labkit::Fields::GL_USER_ID => user.id,
        Labkit::Fields::ERROR_MESSAGE => 'service failed',
        group_id: group.id
      ))
    end
  end
end
