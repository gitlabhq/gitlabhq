# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ProcessSyncEventsService, feature_category: :continuous_integration do
  let!(:group) { create(:group) }
  let!(:project1) { create(:project, group: group) }
  let!(:project2) { create(:project, group: group) }
  let!(:parent_group_1) { create(:group) }
  let!(:parent_group_2) { create(:group) }

  subject(:service) { described_class.new(sync_event_class, hierarchy_class) }

  describe '#perform' do
    subject(:execute) { service.execute }

    context 'for Projects::SyncEvent' do
      let(:sync_event_class) { Projects::SyncEvent }
      let(:hierarchy_class) { ::Ci::ProjectMirror }

      before do
        Projects::SyncEvent.delete_all

        project1.update!(group: parent_group_1)
        project2.update!(group: parent_group_2)
      end

      it { is_expected.to eq(service_results(2, 2, 2)) }

      it 'consumes events' do
        expect { execute }.to change(Projects::SyncEvent, :count).from(2).to(0)

        expect(project1.reload.ci_project_mirror).to have_attributes(
          namespace_id: parent_group_1.id
        )
        expect(project2.reload.ci_project_mirror).to have_attributes(
          namespace_id: parent_group_2.id
        )
      end

      context 'when any event left after processing' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 1)
        end

        it { is_expected.to eq(service_results(2, 1, 1)) }

        it 'enqueues Projects::ProcessSyncEventsWorker' do
          expect(Projects::ProcessSyncEventsWorker).to receive(:perform_async)

          execute
        end
      end

      context 'when no event left after processing' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 2)
        end

        it { is_expected.to eq(service_results(2, 2, 2)) }

        it 'does not enqueue Projects::ProcessSyncEventsWorker' do
          expect(Projects::ProcessSyncEventsWorker).not_to receive(:perform_async)

          execute
        end
      end

      context 'when there is no event' do
        before do
          Projects::SyncEvent.delete_all
        end

        it { is_expected.to eq(service_results(0, 0, nil)) }

        it 'does nothing' do
          expect { execute }.not_to change(Projects::SyncEvent, :count)
        end
      end

      context 'when there is non-executed events' do
        before do
          new_project = create(:project)
          sync_event_class.delete_all

          project1.update!(group: parent_group_2)
          new_project.update!(group: parent_group_1)
          project2.update!(group: parent_group_1)

          @new_project_sync_event = new_project.sync_events.last

          allow(sync_event_class).to receive(:preload_synced_relation).and_return(
            sync_event_class.where.not(id: @new_project_sync_event)
          )
        end

        it { is_expected.to eq(service_results(3, 2, 2)) }

        it 'does not delete non-executed events' do
          expect { execute }.to change(Projects::SyncEvent, :count).from(3).to(1)
          expect(@new_project_sync_event.reload).to be_persisted
        end
      end

      private

      def service_results(total, consumable, processed)
        {
          estimated_total_events: total,
          consumable_events: consumable,
          processed_events: processed
        }.compact
      end
    end

    context 'for Namespaces::SyncEvent' do
      let(:sync_event_class) { Namespaces::SyncEvent }
      let(:hierarchy_class) { ::Ci::NamespaceMirror }

      before do
        Namespaces::SyncEvent.delete_all

        # Creates a sync event for group, and the ProjectNamespace of project1 & project2: 3 in total
        group.update!(parent: parent_group_2)
        # Creates a sync event for parent_group2 and all the children: 4 in total
        parent_group_2.update!(parent: parent_group_1)
      end

      shared_examples 'event consuming' do
        it 'consumes events' do
          expect { execute }.to change(Namespaces::SyncEvent, :count).from(7).to(0)

          expect(group.reload.ci_namespace_mirror).to have_attributes(
            traversal_ids: [parent_group_1.id, parent_group_2.id, group.id]
          )
          expect(parent_group_2.reload.ci_namespace_mirror).to have_attributes(
            traversal_ids: [parent_group_1.id, parent_group_2.id]
          )
          expect(project1.reload.project_namespace).to have_attributes(
            traversal_ids: [parent_group_1.id, parent_group_2.id, group.id, project1.project_namespace.id]
          )
          expect(project2.reload.project_namespace).to have_attributes(
            traversal_ids: [parent_group_1.id, parent_group_2.id, group.id, project2.project_namespace.id]
          )
        end
      end

      context 'when the FFs use_traversal_ids and use_traversal_ids_for_ancestors are disabled' do
        before do
          stub_feature_flags(use_traversal_ids: false, use_traversal_ids_for_ancestors: false)
        end

        it_behaves_like 'event consuming'
      end

      it_behaves_like 'event consuming'

      it 'enqueues Namespaces::ProcessSyncEventsWorker if any left' do
        stub_const("#{described_class}::BATCH_SIZE", 1)

        expect(Namespaces::ProcessSyncEventsWorker).to receive(:perform_async)

        execute
      end

      it 'does not enqueue Namespaces::ProcessSyncEventsWorker if no left' do
        stub_const("#{described_class}::BATCH_SIZE", 7)

        expect(Namespaces::ProcessSyncEventsWorker).not_to receive(:perform_async)

        execute
      end
    end
  end
end
