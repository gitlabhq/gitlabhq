# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ObjectHierarchy do
  let_it_be(:parent, reload: true) { create(:group) }
  let_it_be(:child1) { create(:group, parent: parent) }
  let_it_be(:child2) { create(:group, parent: child1) }

  let(:options) { {} }

  describe '#base_and_ancestors' do
    let(:relation) do
      described_class.new(Group.where(id: child2.id), options: options).base_and_ancestors
    end

    it 'includes the base rows' do
      expect(relation).to include(child2)
    end

    it 'includes all of the ancestors' do
      expect(relation).to include(parent, child1)
    end

    it 'can find ancestors upto a certain level' do
      relation = described_class.new(Group.where(id: child2), options: options).base_and_ancestors(upto: child1)

      expect(relation).to contain_exactly(child2)
    end

    it 'uses ancestors_base #initialize argument' do
      relation = described_class.new(Group.where(id: child2.id), Group.none, options: options).base_and_ancestors

      expect(relation).to include(parent, child1, child2)
    end

    it 'does not allow the use of #update_all' do
      expect { relation.update_all(share_with_group_lock: false) }
        .to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    describe 'hierarchy_order option' do
      let(:relation) do
        described_class.new(Group.where(id: child2.id), options: options).base_and_ancestors(hierarchy_order: hierarchy_order)
      end

      context ':asc' do
        let(:hierarchy_order) { :asc }

        it 'orders by child to parent' do
          expect(relation).to eq([child2, child1, parent])
        end
      end

      context ':desc' do
        let(:hierarchy_order) { :desc }

        it 'orders by parent to child' do
          expect(relation).to eq([parent, child1, child2])
        end
      end
    end
  end

  describe '#base_and_descendants' do
    let(:relation) do
      described_class.new(Group.where(id: parent.id), options: options).base_and_descendants
    end

    it 'includes the base rows' do
      expect(relation).to include(parent)
    end

    it 'includes all the descendants' do
      expect(relation).to include(child1, child2)
    end

    it 'uses descendants_base #initialize argument' do
      relation = described_class.new(Group.none, Group.where(id: parent.id), options: options).base_and_descendants

      expect(relation).to include(parent, child1, child2)
    end

    it 'does not allow the use of #update_all' do
      expect { relation.update_all(share_with_group_lock: false) }
        .to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    context 'when with_depth is true' do
      let(:relation) do
        described_class.new(Group.where(id: parent.id), options: options).base_and_descendants(with_depth: true)
      end

      it 'includes depth in the results' do
        object_depths = {
          parent.id => 1,
          child1.id => 2,
          child2.id => 3
        }

        relation.each do |object|
          expect(object.depth).to eq(object_depths[object.id])
        end
      end
    end
  end

  describe '#descendants' do
    it 'includes only the descendants' do
      relation = described_class.new(Group.where(id: parent), options: options).descendants

      expect(relation).to contain_exactly(child1, child2)
    end
  end

  describe '#max_descendants_depth' do
    subject { described_class.new(base_relation, options: options).max_descendants_depth }

    context 'when base relation is empty' do
      let(:base_relation) { Group.where(id: nil) }

      it { expect(subject).to be_nil }
    end

    context 'when base has no children' do
      let(:base_relation) { Group.where(id: child2) }

      it { expect(subject).to eq(1) }
    end

    context 'when base has grandchildren' do
      let(:base_relation) { Group.where(id: parent) }

      it { expect(subject).to eq(3) }
    end
  end

  describe '#ancestors' do
    it 'includes only the ancestors' do
      relation = described_class.new(Group.where(id: child2), options: options).ancestors

      expect(relation).to contain_exactly(child1, parent)
    end

    it 'can find ancestors upto a certain level' do
      relation = described_class.new(Group.where(id: child2), options: options).ancestors(upto: child1)

      expect(relation).to be_empty
    end
  end

  describe '#all_objects' do
    let(:relation) do
      described_class.new(Group.where(id: child1.id), options: options).all_objects
    end

    it 'includes the base rows' do
      expect(relation).to include(child1)
    end

    it 'includes the ancestors' do
      expect(relation).to include(parent)
    end

    it 'includes the descendants' do
      expect(relation).to include(child2)
    end

    it 'uses ancestors_base #initialize argument for ancestors' do
      relation = described_class.new(Group.where(id: child1.id), Group.where(id: non_existing_record_id), options: options).all_objects

      expect(relation).to include(parent)
    end

    it 'uses descendants_base #initialize argument for descendants' do
      relation = described_class.new(Group.where(id: non_existing_record_id), Group.where(id: child1.id), options: options).all_objects

      expect(relation).to include(child2)
    end

    it 'does not allow the use of #update_all' do
      expect { relation.update_all(share_with_group_lock: false) }
        .to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
