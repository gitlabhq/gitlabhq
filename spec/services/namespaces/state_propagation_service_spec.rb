# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::StatePropagationService, feature_category: :groups_and_projects do
  let_it_be_with_reload(:root_group) { create(:group) }
  let_it_be_with_reload(:subgroup) { create(:group, parent: root_group) }
  let_it_be_with_reload(:leaf_group) { create(:group, parent: subgroup) }

  subject(:service) { described_class.new(root_group.id, 'archived') }

  describe '#execute' do
    let!(:propagation) do
      create(:namespace_state_propagation, :ancestor_inherited_to_archived, namespace: root_group)
    end

    it 'marks the outbox record as processing before propagating' do
      statuses = []

      allow(service).to receive(:propagate).and_wrap_original do |method, *args|
        statuses << propagation.reload.status
        method.call(*args)
      end

      service.execute

      expect(statuses).to eq(['processing'])
    end

    it 'propagates the target state to overwritable descendants', :aggregate_failures do
      service.execute

      expect(subgroup.reload.state).to eq('archived')
      expect(leaf_group.reload.state).to eq('archived')
    end

    it 'deletes the outbox record on completion' do
      service.execute

      expect(Namespaces::StatePropagation.exists?(propagation.id)).to be(false)
    end

    context 'when a descendant is in a non-overwritable state' do
      before do
        leaf_group.update!(state: :deletion_scheduled)
      end

      it 'does not overwrite the higher-precedence descendant', :aggregate_failures do
        service.execute

        expect(subgroup.reload.state).to eq('archived')
        expect(leaf_group.reload.state).to eq('deletion_scheduled')
      end
    end

    context 'when there are no overwritable states' do
      subject(:service) { described_class.new(root_group.id, 'ancestor_inherited') }

      let!(:propagation) do
        create(:namespace_state_propagation, namespace: root_group,
          source_state: :ancestor_inherited, target_state: :ancestor_inherited)
      end

      it 'does not change any descendant state', :aggregate_failures do
        service.execute

        expect(subgroup.reload.state).to eq('ancestor_inherited')
        expect(leaf_group.reload.state).to eq('ancestor_inherited')
      end

      it 'deletes the outbox record' do
        service.execute

        expect(Namespaces::StatePropagation.exists?(propagation.id)).to be(false)
      end
    end

    context 'when the outbox record does not exist' do
      subject(:service) { described_class.new(non_existing_record_id, 'archived') }

      it 'does not change any descendant state and does not raise', :aggregate_failures do
        expect { service.execute }.not_to raise_error

        expect(subgroup.reload.state).to eq('ancestor_inherited')
      end
    end

    context 'when the outbox record is already processing' do
      let!(:propagation) do
        create(:namespace_state_propagation, :processing, :ancestor_inherited_to_archived,
          namespace: root_group)
      end

      it 'leaves descendants and the record untouched', :aggregate_failures do
        service.execute

        expect(subgroup.reload.state).to eq('ancestor_inherited')
        expect(propagation.reload).to be_status_processing
      end
    end

    context 'when propagation fails partway through' do
      before do
        allow(service).to receive(:propagate).and_raise(ActiveRecord::StatementInvalid)
      end

      it 'leaves the outbox record in place as processing for CRON recovery', :aggregate_failures do
        expect { service.execute }.to raise_error(ActiveRecord::StatementInvalid)

        expect(Namespaces::StatePropagation.exists?(propagation.id)).to be(true)
        expect(propagation.reload).to be_status_processing
      end
    end
  end
end
