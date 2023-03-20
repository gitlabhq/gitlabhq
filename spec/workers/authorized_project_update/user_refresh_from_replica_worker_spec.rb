# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::UserRefreshFromReplicaWorker, feature_category: :system_access do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.namespace.owner }

  let(:execute_worker) { subject.perform(user.id) }

  it 'is labeled as low urgency' do
    expect(described_class.get_urgency).to eq(:low)
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { user.id }
  end

  describe '#perform' do
    it 'checks if a project_authorization refresh is needed for the user' do
      expect(AuthorizedProjectUpdate::FindRecordsDueForRefreshService).to(
        receive(:new).with(user).and_call_original)

      execute_worker
    end

    context 'when there are project authorization records due for either removal or addition for a specific user' do
      before do
        user.project_authorizations.delete_all
      end

      it 'enqueues a new project authorization update job for the user' do
        expect(AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker).to receive(:perform_async).with(user.id)

        execute_worker
      end
    end

    context 'when there are no additions or removals to be made to project authorizations for a specific user' do
      it 'does not enqueue a new project authorization update job for the user' do
        expect(AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker).not_to receive(:perform_async)

        execute_worker
      end
    end

    context 'with load balancing enabled' do
      it 'reads from the replica database' do
        expect(Gitlab::Database::LoadBalancing::Session.current).to receive(:use_replicas_for_read_queries).and_call_original

        execute_worker
      end
    end
  end
end
