# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ProcessGroupTransferEventsWorker, feature_category: :portfolio_management do
  let_it_be(:parent_group) { create(:group) }
  let_it_be(:transfer_group) { create(:group, parent: parent_group) }

  let(:worker) { described_class.new }
  let(:group_id) { transfer_group.id }

  let(:event) do
    Groups::GroupTransferedEvent.new(data: {
      group_id: group_id,
      old_root_namespace_id: parent_group.id,
      new_root_namespace_id: parent_group.id
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
  end

  describe '#handle_event' do
    let(:update_traversal_ids_worker) { WorkItems::UpdateNamespaceTraversalIdsWorker }

    subject(:handle_event) { worker.handle_event(event) }

    before do
      allow(update_traversal_ids_worker).to receive(:bulk_perform_async)
    end

    context 'when there is no group associated with the event' do
      let(:group_id) { non_existing_record_id }

      it 'does not call UpdateNamespaceTraversalIdsWorker' do
        handle_event

        expect(update_traversal_ids_worker).not_to have_received(:bulk_perform_async)
      end
    end

    context 'when there is a group associated with the event' do
      let_it_be(:transfer_group_project) { create(:project, group: transfer_group) }
      let_it_be(:subgroup) { create(:group, parent: transfer_group) }
      let_it_be(:subgroup_project) { create(:project, group: subgroup) }
      let_it_be(:nested_subgroup) { create(:group, parent: subgroup) }
      let_it_be(:nested_subgroup_project) { create(:project, group: nested_subgroup) }

      let_it_be(:other_project) { create(:project, group: parent_group) }

      it 'bulk perform async UpdateNamespaceTraversalIdsWorker' do
        expect(update_traversal_ids_worker)
          .to receive(:bulk_perform_async_with_contexts)
            .once
            .with(
              match_array([
                transfer_group.id,
                transfer_group_project.project_namespace_id,
                subgroup.id,
                subgroup_project.project_namespace_id,
                nested_subgroup.id,
                nested_subgroup_project.project_namespace_id
              ]),
              arguments_proc: kind_of(Proc),
              context_proc: kind_of(Proc)
            )

        handle_event
      end

      describe 'iterating over descendant namespaces in batches' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 2)
        end

        it 'schedules the worker multiple times' do
          expect(update_traversal_ids_worker).to receive(:bulk_perform_async_with_contexts)
            .once
            .with(match_array([transfer_group.id, transfer_group_project.project_namespace_id, subgroup.id]), anything)

          expect(update_traversal_ids_worker).to receive(:bulk_perform_async_with_contexts)
            .once
            .with(match_array([subgroup_project.project_namespace_id, nested_subgroup.id]), anything)

          expect(update_traversal_ids_worker).to receive(:bulk_perform_async_with_contexts)
            .once
            .with(match_array([nested_subgroup_project.project_namespace_id]), anything)

          handle_event
        end
      end
    end
  end
end
