# frozen_string_literal: true

RSpec.shared_examples 'namespace traversal' do
  shared_examples 'recursive version' do |method|
    let(:recursive_method) { "recursive_#{method}" }

    it "is equivalent to ##{method}" do
      groups.each do |group|
        expect(group.public_send(method)).to match_array group.public_send(recursive_method)
      end
    end

    it "makes a recursive query" do
      groups.each do |group|
        expect { group.public_send(recursive_method).try(:load) }.to make_queries_matching(/WITH RECURSIVE/)
      end
    end
  end

  let_it_be(:group) { create(:group) }
  let_it_be(:nested_group) { create(:group, parent: group) }
  let_it_be(:deep_nested_group) { create(:group, parent: nested_group) }
  let_it_be(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }
  let_it_be(:groups) { [group, nested_group, deep_nested_group, very_deep_nested_group] }

  describe '#root_ancestor' do
    it 'returns the correct root ancestor' do
      expect(group.root_ancestor).to eq(group)
      expect(nested_group.root_ancestor).to eq(group)
      expect(deep_nested_group.root_ancestor).to eq(group)
    end

    describe '#recursive_root_ancestor' do
      it "is equivalent to #recursive_root_ancestor" do
        groups.each do |group|
          expect(group.root_ancestor).to eq(group.recursive_root_ancestor)
        end
      end
    end
  end

  describe '#self_and_hierarchy' do
    let!(:another_group) { create(:group) }
    let!(:another_group_nested) { create(:group, parent: another_group) }

    it 'returns the correct tree' do
      expect(group.self_and_hierarchy).to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
      expect(nested_group.self_and_hierarchy).to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
      expect(very_deep_nested_group.self_and_hierarchy).to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
    end

    describe '#recursive_self_and_hierarchy' do
      it_behaves_like 'recursive version', :self_and_hierarchy
    end
  end

  describe '#ancestors' do
    it 'returns the correct ancestors' do
      # #reload is called to make sure traversal_ids are reloaded
      expect(very_deep_nested_group.reload.ancestors).to contain_exactly(group, nested_group, deep_nested_group)
      expect(deep_nested_group.reload.ancestors).to contain_exactly(group, nested_group)
      expect(nested_group.reload.ancestors).to contain_exactly(group)
      expect(group.reload.ancestors).to eq([])
    end

    describe '#recursive_ancestors' do
      let_it_be(:groups) { [nested_group, deep_nested_group, very_deep_nested_group] }

      it_behaves_like 'recursive version', :ancestors
    end
  end

  describe '#ancestor_ids' do
    it 'returns the correct ancestor ids' do
      expect(very_deep_nested_group.ancestor_ids).to contain_exactly(group.id, nested_group.id, deep_nested_group.id)
      expect(deep_nested_group.ancestor_ids).to contain_exactly(group.id, nested_group.id)
      expect(nested_group.ancestor_ids).to contain_exactly(group.id)
      expect(group.ancestor_ids).to be_empty
    end

    describe '#recursive_ancestor_ids' do
      let_it_be(:groups) { [nested_group, deep_nested_group, very_deep_nested_group] }

      it_behaves_like 'recursive version', :ancestor_ids
    end
  end

  describe '#self_and_ancestors' do
    it 'returns the correct ancestors' do
      expect(very_deep_nested_group.self_and_ancestors).to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
      expect(deep_nested_group.self_and_ancestors).to contain_exactly(group, nested_group, deep_nested_group)
      expect(nested_group.self_and_ancestors).to contain_exactly(group, nested_group)
      expect(group.self_and_ancestors).to contain_exactly(group)
    end

    describe '#recursive_self_and_ancestors' do
      let_it_be(:groups) { [nested_group, deep_nested_group, very_deep_nested_group] }

      it_behaves_like 'recursive version', :self_and_ancestors
    end
  end

  describe '#self_and_ancestor_ids' do
    it 'returns the correct ancestor ids' do
      expect(very_deep_nested_group.self_and_ancestor_ids).to contain_exactly(group.id, nested_group.id, deep_nested_group.id, very_deep_nested_group.id)
      expect(deep_nested_group.self_and_ancestor_ids).to contain_exactly(group.id, nested_group.id, deep_nested_group.id)
      expect(nested_group.self_and_ancestor_ids).to contain_exactly(group.id, nested_group.id)
      expect(group.self_and_ancestor_ids).to contain_exactly(group.id)
    end

    describe '#recursive_self_and_ancestor_ids' do
      let_it_be(:groups) { [nested_group, deep_nested_group, very_deep_nested_group] }

      it_behaves_like 'recursive version', :self_and_ancestor_ids
    end
  end

  describe '#descendants' do
    let!(:another_group) { create(:group) }
    let!(:another_group_nested) { create(:group, parent: another_group) }

    it 'returns the correct descendants' do
      expect(very_deep_nested_group.descendants.to_a).to eq([])
      expect(deep_nested_group.descendants.to_a).to include(very_deep_nested_group)
      expect(nested_group.descendants.to_a).to include(deep_nested_group, very_deep_nested_group)
      expect(group.descendants.to_a).to include(nested_group, deep_nested_group, very_deep_nested_group)
    end

    describe '#recursive_descendants' do
      it_behaves_like 'recursive version', :descendants
    end
  end

  describe '#self_and_descendants' do
    let!(:another_group) { create(:group) }
    let!(:another_group_nested) { create(:group, parent: another_group) }

    it 'returns the correct descendants' do
      expect(very_deep_nested_group.self_and_descendants).to contain_exactly(very_deep_nested_group)
      expect(deep_nested_group.self_and_descendants).to contain_exactly(deep_nested_group, very_deep_nested_group)
      expect(nested_group.self_and_descendants).to contain_exactly(nested_group, deep_nested_group, very_deep_nested_group)
      expect(group.self_and_descendants).to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
    end

    describe '#recursive_self_and_descendants' do
      let_it_be(:groups) { [group, nested_group, deep_nested_group] }

      it_behaves_like 'recursive version', :self_and_descendants
    end
  end

  describe '#self_and_descendant_ids' do
    subject { group.self_and_descendant_ids.pluck(:id) }

    it { is_expected.to contain_exactly(group.id, nested_group.id, deep_nested_group.id, very_deep_nested_group.id) }

    describe '#recursive_self_and_descendant_ids' do
      it_behaves_like 'recursive version', :self_and_descendant_ids
    end
  end
end
