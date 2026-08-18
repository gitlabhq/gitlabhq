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
