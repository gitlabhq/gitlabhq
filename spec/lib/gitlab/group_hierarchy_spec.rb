require 'spec_helper'

describe Gitlab::GroupHierarchy, :postgresql do
  let!(:parent) { create(:group) }
  let!(:child1) { create(:group, parent: parent) }
  let!(:child2) { create(:group, parent: child1) }

  describe '#base_and_ancestors' do
    let(:relation) do
      described_class.new(Group.where(id: child2.id)).base_and_ancestors
    end

    it 'includes the base rows' do
      expect(relation).to include(child2)
    end

    it 'includes all of the ancestors' do
      expect(relation).to include(parent, child1)
    end

    it 'uses ancestors_base #initialize argument' do
      relation = described_class.new(Group.where(id: child2.id), Group.none).base_and_ancestors

      expect(relation).to include(parent, child1, child2)
    end
  end

  describe '#base_and_descendants' do
    let(:relation) do
      described_class.new(Group.where(id: parent.id)).base_and_descendants
    end

    it 'includes the base rows' do
      expect(relation).to include(parent)
    end

    it 'includes all the descendants' do
      expect(relation).to include(child1, child2)
    end

    it 'uses descendants_base #initialize argument' do
      relation = described_class.new(Group.none, Group.where(id: parent.id)).base_and_descendants

      expect(relation).to include(parent, child1, child2)
    end
  end

  describe '#all_groups' do
    let(:relation) do
      described_class.new(Group.where(id: child1.id)).all_groups
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
      relation = described_class.new(Group.where(id: child1.id), Group.where(id: Group.maximum(:id).succ)).all_groups

      expect(relation).to include(parent)
    end

    it 'uses descendants_base #initialize argument for descendants' do
      relation = described_class.new(Group.where(id: Group.maximum(:id).succ), Group.where(id: child1.id)).all_groups

      expect(relation).to include(child2)
    end
  end
end
