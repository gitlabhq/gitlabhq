# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::TransferWorkerHelper, feature_category: :groups_and_projects do
  let(:worker_class) do
    Class.new do
      include Namespaces::TransferWorkerHelper

      public :cancel_stale_transfer_state
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

      it 'cancels the state and logs a warning' do
        allow(Gitlab::AppLogger).to receive(:warn)

        worker.cancel_stale_transfer_state(group, group_id: group.id)

        expect(group.reload).to be_ancestor_inherited
        expect(Gitlab::AppLogger).to have_received(:warn).with(hash_including(
          message: 'Cancelling stale transfer state',
          group_id: group.id
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
end
