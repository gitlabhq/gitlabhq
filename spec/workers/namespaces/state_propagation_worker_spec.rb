# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::StatePropagationWorker, feature_category: :groups_and_projects do
  let_it_be_with_reload(:root_group) { create(:group) }
  let_it_be_with_reload(:subgroup) { create(:group, parent: root_group) }
  let_it_be_with_reload(:leaf_group) { create(:group, parent: subgroup) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    let!(:propagation) do
      create(:namespace_state_propagation, :ancestor_inherited_to_archived, namespace: root_group)
    end

    it 'delegates to Namespaces::StatePropagationService' do
      service = instance_double(Namespaces::StatePropagationService)

      expect(Namespaces::StatePropagationService)
        .to receive(:new).with(root_group.id, 'archived').and_return(service)
      expect(service).to receive(:execute)

      worker.perform(root_group.id, 'archived')
    end

    it 'propagates the target state to overwritable descendants and removes the outbox record',
      :aggregate_failures do
      worker.perform(root_group.id, 'archived')

      expect(subgroup.reload.state).to eq('archived')
      expect(leaf_group.reload.state).to eq('archived')
      expect(Namespaces::StatePropagation.exists?(propagation.id)).to be(false)
    end

    it 'does not count a failure' do
      expect(Gitlab::NamespaceStatePropagation::Metrics).not_to receive(:increment_failures)

      worker.perform(root_group.id, 'archived')
    end

    context 'when the service raises an error' do
      before do
        allow_next_instance_of(Namespaces::StatePropagationService) do |service|
          allow(service).to receive(:execute).and_raise(ActiveRecord::StatementInvalid)
        end
      end

      it 'counts the failure and re-raises', :aggregate_failures do
        expect(Gitlab::NamespaceStatePropagation::Metrics).to receive(:increment_failures).with('archived')

        expect { worker.perform(root_group.id, 'archived') }.to raise_error(ActiveRecord::StatementInvalid)
      end

      it 'labels an unknown target state as unknown' do
        expect(Gitlab::NamespaceStatePropagation::Metrics).to receive(:increment_failures).with('unknown')

        expect { worker.perform(root_group.id, 'bogus') }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end

  describe '#perform state preservation' do
    def preserved_state(namespace)
      namespace.state_metadata.dig('preserved_states', 'schedule_deletion')
    end

    context 'when propagating deletion_scheduled' do
      let!(:propagation) do
        create(:namespace_state_propagation, namespace: root_group,
          source_state: :ancestor_inherited, target_state: :deletion_scheduled)
      end

      before do
        subgroup.update!(state: :archived)
      end

      it 'preserves the previous state of each overwritten descendant' do
        worker.perform(root_group.id, 'deletion_scheduled')

        subgroup.reload
        leaf_group.reload

        expect(subgroup.state).to eq('deletion_scheduled')
        expect(leaf_group.state).to eq('deletion_scheduled')
        expect(preserved_state(subgroup)).to eq('archived')
        expect(preserved_state(leaf_group)).to eq('ancestor_inherited')
      end
    end

    context 'when propagating ancestor_inherited (unarchive)' do
      let!(:propagation) do
        create(:namespace_state_propagation, :archived_to_ancestor_inherited, namespace: root_group)
      end

      before do
        subgroup.update!(state: :archived)
        subgroup.state_metadata['preserved_states'] = { 'schedule_deletion' => 'archived' }
        subgroup.namespace_details.save!
      end

      it 'clears preserved states from overwritten descendants' do
        worker.perform(root_group.id, 'ancestor_inherited')

        subgroup.reload

        expect(subgroup.state).to eq('ancestor_inherited')
        expect(subgroup.state_metadata).not_to have_key('preserved_states')
      end
    end

    context 'with a nested hierarchy (archived subgroup inside deletion_scheduled parent)' do
      let_it_be_with_reload(:nested_leaf) { create(:group, parent: leaf_group) }

      let!(:propagation) do
        create(:namespace_state_propagation, namespace: root_group,
          source_state: :ancestor_inherited, target_state: :deletion_scheduled)
      end

      before do
        subgroup.update!(state: :archived)
        leaf_group.update!(state: :archived)
        nested_leaf.update!(state: :archived)
      end

      it 'preserves archived for every descendant below the archived subgroup' do
        worker.perform(root_group.id, 'deletion_scheduled')

        expect([subgroup, leaf_group, nested_leaf].map { |group| preserved_state(group.reload) })
          .to all(eq('archived'))
      end
    end

    context 'when cancelling a deletion (deletion_scheduled -> ancestor_inherited)' do
      let!(:propagation) do
        create(:namespace_state_propagation, namespace: root_group,
          source_state: :deletion_scheduled, target_state: :ancestor_inherited)
      end

      before do
        subgroup.update!(state: :deletion_scheduled)
        subgroup.namespace_details.update!(state_metadata: { preserved_states: { schedule_deletion: 'archived' } })
      end

      it 'keeps preserved states for the restore to use' do
        worker.perform(root_group.id, 'ancestor_inherited')

        expect(preserved_state(subgroup.reload)).to eq('archived')
      end
    end
  end

  it_behaves_like 'an idempotent worker' do
    let!(:propagation) do
      create(:namespace_state_propagation, :ancestor_inherited_to_archived, namespace: root_group)
    end

    let(:job_args) { [root_group.id, 'archived'] }

    it 'leaves descendants archived and removes the outbox record', :aggregate_failures do
      perform_idempotent_work

      expect(subgroup.reload.state).to eq('archived')
      expect(Namespaces::StatePropagation.exists?(namespace_id: root_group.id)).to be(false)
    end
  end
end
