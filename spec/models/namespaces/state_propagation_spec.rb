# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::StatePropagation, feature_category: :groups_and_projects do
  let_it_be(:namespace) { create(:namespace) }

  describe 'associations' do
    it { is_expected.to belong_to(:namespace).required }
  end

  describe 'validations' do
    subject { build(:namespace_state_propagation) }

    it { is_expected.to validate_presence_of(:source_state) }
    it { is_expected.to validate_presence_of(:target_state) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe 'enums' do
    it 'defines status enum' do
      expect(described_class.statuses).to eq({ 'pending' => 0, 'processing' => 1 })
    end

    it 'defines source_state enum' do
      expect(described_class.source_states).to eq({
        'ancestor_inherited' => 0,
        'archived' => 1,
        'deletion_scheduled' => 2,
        'creation_in_progress' => 3,
        'deletion_in_progress' => 4,
        'transfer_in_progress' => 5,
        'maintenance' => 6,
        'transfer_scheduled' => 7
      })
    end

    it 'defines target_state enum' do
      expect(described_class.target_states).to eq({
        'ancestor_inherited' => 0,
        'archived' => 1,
        'deletion_scheduled' => 2,
        'creation_in_progress' => 3,
        'deletion_in_progress' => 4,
        'transfer_in_progress' => 5,
        'maintenance' => 6,
        'transfer_scheduled' => 7
      })
    end
  end

  describe 'scopes' do
    let_it_be(:pending_propagation) do
      create(:namespace_state_propagation, :pending, namespace: namespace, target_state: :archived)
    end

    let_it_be(:processing_propagation) do
      create(:namespace_state_propagation, :processing, namespace: namespace, target_state: :deletion_scheduled)
    end

    describe '.pending' do
      it 'returns only pending propagations' do
        expect(described_class.pending).to contain_exactly(pending_propagation)
      end
    end

    describe '.processing' do
      it 'returns only processing propagations' do
        expect(described_class.processing).to contain_exactly(processing_propagation)
      end
    end

    describe '.order_by_created_at_asc' do
      it 'orders by created_at ascending' do
        oldest = create(:namespace_state_propagation, namespace: create(:namespace), created_at: 2.days.ago)
        newest = create(:namespace_state_propagation, namespace: create(:namespace), created_at: 1.day.from_now)

        ids = described_class.where(id: [oldest.id, pending_propagation.id,
          newest.id]).order_by_created_at_asc.pluck(:id)

        expect(ids).to eq([oldest.id, pending_propagation.id, newest.id])
      end
    end
  end

  describe 'unique constraint' do
    it 'prevents duplicate pending records for same namespace and target_state' do
      create(:namespace_state_propagation, namespace: namespace, target_state: :archived, status: :pending)

      duplicate = build(:namespace_state_propagation, namespace: namespace, target_state: :archived, status: :pending)

      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'prevents duplicate processing records for same namespace and target_state' do
      create(:namespace_state_propagation, namespace: namespace, target_state: :archived, status: :processing)

      duplicate = build(:namespace_state_propagation, namespace: namespace, target_state: :archived,
        status: :processing)

      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows another record for the same namespace if target_state differs' do
      create(:namespace_state_propagation, namespace: namespace, target_state: :archived, status: :pending)

      other = build(:namespace_state_propagation, namespace: namespace, target_state: :deletion_scheduled,
        status: :pending)

      expect { other.save! }.not_to raise_error
    end
  end

  describe 'cascade deletion' do
    it 'deletes propagation records when namespace is deleted', :aggregate_failures do
      propagation = create(:namespace_state_propagation, namespace: namespace)

      expect { namespace.destroy! }.to change { described_class.count }.by(-1)
      expect(described_class.find_by(id: propagation.id)).to be_nil
    end
  end
end
