# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ProcessProjectTransferEventsWorker, feature_category: :portfolio_management do
  let_it_be(:old_parent) { create(:group) }
  let_it_be(:new_parent) { create(:group) }
  let_it_be(:project) { create(:project, namespace: new_parent) }

  let(:project_id) { project.id }
  let(:namespace) { project.project_namespace }
  let(:worker) { described_class.new }

  let(:event) do
    ::Projects::ProjectTransferedEvent.new(data: {
      project_id: project_id,
      old_namespace_id: old_parent.id,
      old_root_namespace_id: old_parent.id,
      new_namespace_id: new_parent.id,
      new_root_namespace_id: new_parent.id
    })
  end

  it 'has the `until_executing` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executing)
  end

  it 'has a concurrency limit' do
    expect(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap.limit_for(worker: described_class)).to eq(200)
  end

  describe ".handles_event?" do
    subject(:handles_event?) { described_class.handles_event?(event) }

    it_behaves_like 'subscribes to event'

    it { is_expected.to be_truthy }
  end

  describe '#handle_event' do
    subject(:handle_event) { worker.handle_event(event) }

    let_it_be(:work_item) { create(:work_item, project: project) }

    before do
      work_item.update_column(:namespace_traversal_ids, [old_parent.id, project.project_namespace.id])
    end

    it 'updates the namespace_traversal_ids of the work item', :sidekiq_inline do
      expect { handle_event }.to change { work_item.reload.namespace_traversal_ids }
        .from([old_parent.id, project.project_namespace.id])
        .to(project.project_namespace.traversal_ids)
    end

    it 'enqueues the UpdateNamespaceTraversalIdsWorker with the correct namespace id' do
      expect(WorkItems::UpdateNamespaceTraversalIdsWorker).to receive(:perform_async)
        .with(namespace.id)

      handle_event
    end

    context 'when there is no project associated with the event' do
      let(:project_id) { non_existing_record_id }

      it 'does not enqueue the UpdateNamespaceTraversalIdsWorker' do
        expect(WorkItems::UpdateNamespaceTraversalIdsWorker).not_to receive(:perform_async)

        handle_event
      end
    end
  end
end
