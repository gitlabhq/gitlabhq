# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PendingBuilds::UpdateGroupWorker, '#perform', feature_category: :groups_and_projects do
  let(:worker) { described_class.new }

  context 'when a group is not provided' do
    it 'does not call the service' do
      expect(::Ci::UpdatePendingBuildService).not_to receive(:new)
    end
  end

  context 'when everything is ok' do
    let_it_be_with_refind(:group) { create(:group) }
    let_it_be_with_refind(:child_group) { create(:group, parent: group) }
    let_it_be_with_refind(:grandchild_group) { create(:group, parent: child_group) }
    let_it_be_with_refind(:other_group) { create(:group) }

    let(:update_pending_build_service) { instance_double(::Ci::UpdatePendingBuildService) }
    let(:update_pending_build_service2) { instance_double(::Ci::UpdatePendingBuildService) }
    let(:update_pending_build_service3) { instance_double(::Ci::UpdatePendingBuildService) }

    it 'calls the service' do
      expect(::Ci::UpdatePendingBuildService).to receive(:new).with(group, { namespace_id: group.id })
        .and_return(update_pending_build_service)
      expect(::Ci::UpdatePendingBuildService).to receive(:new).with(child_group, { namespace_id: child_group.id })
        .and_return(update_pending_build_service2)
      expect(::Ci::UpdatePendingBuildService).to receive(:new).with(grandchild_group, { namespace_id: grandchild_group.id })
        .and_return(update_pending_build_service3)
      expect(update_pending_build_service).to receive(:execute)
      expect(update_pending_build_service2).to receive(:execute)
      expect(update_pending_build_service3).to receive(:execute)

      worker.perform(group.id, { 'namespace_id' => group.id })
    end

    include_examples 'an idempotent worker' do
      let(:pending_build) { create(:ci_pending_build) }
      let(:update_params) { { 'namespace_id' => pending_build.namespace_id } }
      let(:job_args) { [pending_build.namespace_id, update_params] }

      it 'updates the pending builds' do
        subject

        expect(pending_build.reload.namespace_id).to eq(update_params['namespace_id'])
      end
    end

    context 'when namespace_traversal_ids and namespace_id are specified' do
      before do
        group.parent = other_group
        group.save!
        group.reload # Ensure group traversal_ids are recalculated
      end

      it 'calls the service namespace_traversal_ids for each group' do
        new_traversal_ids = other_group.traversal_ids + [group.id]

        expect(::Ci::UpdatePendingBuildService).to receive(:new)
          .with(group, { namespace_id: group.id, namespace_traversal_ids: new_traversal_ids })
          .and_return(update_pending_build_service)
        expect(::Ci::UpdatePendingBuildService).to receive(:new)
          .with(child_group, { namespace_id: child_group.id, namespace_traversal_ids: new_traversal_ids + [child_group.id] })
          .and_return(update_pending_build_service2)
        expect(::Ci::UpdatePendingBuildService).to receive(:new)
          .with(
            grandchild_group,
            { namespace_id: grandchild_group.id, namespace_traversal_ids: new_traversal_ids + [child_group.id, grandchild_group.id] })
          .and_return(update_pending_build_service3)
        expect(update_pending_build_service).to receive(:execute)
        expect(update_pending_build_service2).to receive(:execute)
        expect(update_pending_build_service3).to receive(:execute)

        worker.perform(group.id, { 'namespace_id' => group.id, 'namespace_traversal_ids' => new_traversal_ids })
      end
    end
  end
end
