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
  let_it_be(:project) { create(:project, group: nested_group) }
  let_it_be(:project_namespace) { project.project_namespace }

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
      expect(very_deep_nested_group.ancestors).to contain_exactly(group, nested_group, deep_nested_group)
      expect(deep_nested_group.ancestors).to contain_exactly(group, nested_group)
      expect(nested_group.ancestors).to contain_exactly(group)
      expect(group.ancestors).to eq([])
      expect(project_namespace.ancestors).to be_empty
    end

    context 'with asc hierarchy_order' do
      it 'returns the correct ancestors' do
        expect(very_deep_nested_group.ancestors(hierarchy_order: :asc)).to eq [deep_nested_group, nested_group, group]
        expect(deep_nested_group.ancestors(hierarchy_order: :asc)).to eq [nested_group, group]
        expect(nested_group.ancestors(hierarchy_order: :asc)).to eq [group]
        expect(group.ancestors(hierarchy_order: :asc)).to eq([])
        expect(project_namespace.ancestors(hierarchy_order: :asc)).to be_empty
      end
    end

    context 'with desc hierarchy_order' do
      it 'returns the correct ancestors' do
        expect(very_deep_nested_group.ancestors(hierarchy_order: :desc)).to eq [group, nested_group, deep_nested_group]
        expect(deep_nested_group.ancestors(hierarchy_order: :desc)).to eq [group, nested_group]
        expect(nested_group.ancestors(hierarchy_order: :desc)).to eq [group]
        expect(group.ancestors(hierarchy_order: :desc)).to eq([])
        expect(project_namespace.ancestors(hierarchy_order: :desc)).to be_empty
      end
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
      expect(project_namespace.ancestor_ids).to be_empty
    end

    context 'with asc hierarchy_order' do
      it 'returns the correct ancestor ids' do
        expect(very_deep_nested_group.ancestor_ids(hierarchy_order: :asc)).to eq [deep_nested_group.id, nested_group.id, group.id]
        expect(deep_nested_group.ancestor_ids(hierarchy_order: :asc)).to eq [nested_group.id, group.id]
        expect(nested_group.ancestor_ids(hierarchy_order: :asc)).to eq [group.id]
        expect(group.ancestor_ids(hierarchy_order: :asc)).to eq([])
        expect(project_namespace.ancestor_ids(hierarchy_order: :asc)).to eq([])
      end
    end

    context 'with desc hierarchy_order' do
      it 'returns the correct ancestor ids' do
        expect(very_deep_nested_group.ancestor_ids(hierarchy_order: :desc)).to eq [group.id, nested_group.id, deep_nested_group.id]
        expect(deep_nested_group.ancestor_ids(hierarchy_order: :desc)).to eq [group.id, nested_group.id]
        expect(nested_group.ancestor_ids(hierarchy_order: :desc)).to eq [group.id]
        expect(group.ancestor_ids(hierarchy_order: :desc)).to eq([])
        expect(project_namespace.ancestor_ids(hierarchy_order: :desc)).to eq([])
      end
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
      expect(project_namespace.self_and_ancestors).to contain_exactly(project_namespace)
    end

    context 'with asc hierarchy_order' do
      it 'returns the correct ancestors' do
        expect(very_deep_nested_group.self_and_ancestors(hierarchy_order: :asc)).to eq [very_deep_nested_group, deep_nested_group, nested_group, group]
        expect(deep_nested_group.self_and_ancestors(hierarchy_order: :asc)).to eq [deep_nested_group, nested_group, group]
        expect(nested_group.self_and_ancestors(hierarchy_order: :asc)).to eq [nested_group, group]
        expect(group.self_and_ancestors(hierarchy_order: :asc)).to eq([group])
        expect(project_namespace.self_and_ancestors(hierarchy_order: :asc)).to eq([project_namespace])
      end
    end

    context 'with desc hierarchy_order' do
      it 'returns the correct ancestors' do
        expect(very_deep_nested_group.self_and_ancestors(hierarchy_order: :desc)).to eq [group, nested_group, deep_nested_group, very_deep_nested_group]
        expect(deep_nested_group.self_and_ancestors(hierarchy_order: :desc)).to eq [group, nested_group, deep_nested_group]
        expect(nested_group.self_and_ancestors(hierarchy_order: :desc)).to eq [group, nested_group]
        expect(group.self_and_ancestors(hierarchy_order: :desc)).to eq([group])
        expect(project_namespace.self_and_ancestors(hierarchy_order: :desc)).to eq([project_namespace])
      end
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
      expect(project_namespace.self_and_ancestor_ids).to contain_exactly(project_namespace.id)
    end

    context 'with asc hierarchy_order' do
      it 'returns the correct ancestor ids' do
        expect(very_deep_nested_group.self_and_ancestor_ids(hierarchy_order: :asc)).to eq [very_deep_nested_group.id, deep_nested_group.id, nested_group.id, group.id]
        expect(deep_nested_group.self_and_ancestor_ids(hierarchy_order: :asc)).to eq [deep_nested_group.id, nested_group.id, group.id]
        expect(nested_group.self_and_ancestor_ids(hierarchy_order: :asc)).to eq [nested_group.id, group.id]
        expect(group.self_and_ancestor_ids(hierarchy_order: :asc)).to eq([group.id])
        expect(project_namespace.self_and_ancestor_ids(hierarchy_order: :asc)).to eq([project_namespace.id])
      end
    end

    context 'with desc hierarchy_order' do
      it 'returns the correct ancestor ids' do
        expect(very_deep_nested_group.self_and_ancestor_ids(hierarchy_order: :desc)).to eq [group.id, nested_group.id, deep_nested_group.id, very_deep_nested_group.id]
        expect(deep_nested_group.self_and_ancestor_ids(hierarchy_order: :desc)).to eq [group.id, nested_group.id, deep_nested_group.id]
        expect(nested_group.self_and_ancestor_ids(hierarchy_order: :desc)).to eq [group.id, nested_group.id]
        expect(group.self_and_ancestor_ids(hierarchy_order: :desc)).to eq([group.id])
        expect(project_namespace.self_and_ancestor_ids(hierarchy_order: :desc)).to eq([project_namespace.id])
      end
    end

    describe '#recursive_self_and_ancestor_ids' do
      let_it_be(:groups) { [nested_group, deep_nested_group, very_deep_nested_group] }

      it_behaves_like 'recursive version', :self_and_ancestor_ids
    end
  end

  shared_examples '#ancestors_upto' do
    let(:parent) { create(:group) }
    let(:child) { create(:group, parent: parent) }
    let(:child2) { create(:group, parent: child) }

    it 'returns all ancestors when no namespace is given' do
      expect(child2.ancestors_upto).to contain_exactly(child, parent)
    end

    it 'includes ancestors upto but excluding the given ancestor' do
      expect(child2.ancestors_upto(parent)).to contain_exactly(child)
    end

    context 'with asc hierarchy_order' do
      it 'returns the correct ancestor ids' do
        expect(child2.ancestors_upto(hierarchy_order: :asc)).to eq([child, parent])
      end
    end

    context 'with desc hierarchy_order' do
      it 'returns the correct ancestor ids' do
        expect(child2.ancestors_upto(hierarchy_order: :desc)).to eq([parent, child])
      end
    end

    describe '#recursive_self_and_ancestor_ids' do
      it 'is equivalent to ancestors_upto' do
        recursive_result = child2.recursive_ancestors_upto(parent)
        linear_result = child2.ancestors_upto(parent)
        expect(linear_result).to match_array recursive_result
      end

      it 'makes a recursive query' do
        expect { child2.recursive_ancestors_upto.try(:load) }.to make_queries_matching(/WITH RECURSIVE/)
      end
    end
  end

  describe '#ancestors_upto' do
    include_examples '#ancestors_upto'
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

    it 'does not include project namespaces' do
      expect(group.descendants.to_a).not_to include(project_namespace)
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

    it 'includes project namespaces when scope is Namespace' do
      expect(very_deep_nested_group.self_and_descendants(skope: Namespace))
        .to contain_exactly(very_deep_nested_group)
      expect(deep_nested_group.self_and_descendants(skope: Namespace))
        .to contain_exactly(deep_nested_group, very_deep_nested_group)
      expect(nested_group.self_and_descendants(skope: Namespace))
        .to contain_exactly(nested_group, deep_nested_group, very_deep_nested_group, project_namespace)
      expect(group.self_and_descendants(skope: Namespace))
        .to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group, project_namespace)
    end

    describe '#recursive_self_and_descendants' do
      let_it_be(:groups) { [group, nested_group, deep_nested_group] }

      it_behaves_like 'recursive version', :self_and_descendants

      it 'returns the correct descendants' do
        expect(very_deep_nested_group.recursive_self_and_descendants)
          .to contain_exactly(very_deep_nested_group)
        expect(deep_nested_group.recursive_self_and_descendants)
          .to contain_exactly(deep_nested_group, very_deep_nested_group)
        expect(nested_group.recursive_self_and_descendants)
          .to contain_exactly(nested_group, deep_nested_group, very_deep_nested_group)
        expect(group.recursive_self_and_descendants)
          .to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
      end

      it 'includes project namespaces when scope is Namespace' do
        expect(very_deep_nested_group.recursive_self_and_descendants(skope: Namespace))
          .to contain_exactly(very_deep_nested_group)
        expect(deep_nested_group.recursive_self_and_descendants(skope: Namespace))
          .to contain_exactly(deep_nested_group, very_deep_nested_group)
        expect(nested_group.recursive_self_and_descendants(skope: Namespace))
          .to contain_exactly(nested_group, deep_nested_group, very_deep_nested_group, project_namespace)
        expect(group.recursive_self_and_descendants(skope: Namespace))
          .to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group, project_namespace)
      end
    end
  end

  describe 'all_project_ids' do
    it 'is a AR relation' do
      expect(group.all_project_ids).to be_kind_of(ActiveRecord::Relation)
    end

    it_behaves_like 'recursive version', :all_project_ids
  end

  describe '#self_and_descendant_ids' do
    subject { group.self_and_descendant_ids.pluck(:id) }

    it { is_expected.to contain_exactly(group.id, nested_group.id, deep_nested_group.id, very_deep_nested_group.id) }

    it 'includes project namespaces when when scope is Namespace' do
      expect(group.self_and_descendant_ids(skope: Namespace).pluck(:id))
        .to contain_exactly(
          group.id, nested_group.id, deep_nested_group.id, very_deep_nested_group.id, project_namespace.id
        )
    end

    describe '#recursive_self_and_descendant_ids' do
      it_behaves_like 'recursive version', :self_and_descendant_ids

      it 'includes project namespaces when when scope is Namespace' do
        expect(group.recursive_self_and_descendant_ids(skope: Namespace).pluck(:id))
          .to contain_exactly(
            group.id, nested_group.id, deep_nested_group.id, very_deep_nested_group.id, project_namespace.id
          )
      end
    end
  end
end
