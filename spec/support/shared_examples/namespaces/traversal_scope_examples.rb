# frozen_string_literal: true

RSpec.shared_examples 'namespace traversal scopes' do
  let_it_be(:organization) { create(:organization) }

  # Hierarchy 1
  let_it_be(:group_1) { create(:group, organization: organization) }
  let_it_be(:nested_group_1) { create(:group, parent: group_1) }
  let_it_be(:deep_nested_group_1) { create(:group, parent: nested_group_1) }

  # Hierarchy 2
  let_it_be(:group_2) { create(:group, organization: organization) }
  let_it_be(:nested_group_2) { create(:group, parent: group_2) }
  let_it_be(:deep_nested_group_2) { create(:group, parent: nested_group_2) }

  # All groups
  let_it_be(:groups) do
    [
      group_1, nested_group_1, deep_nested_group_1,
      group_2, nested_group_2, deep_nested_group_2
    ]
  end

  describe '.as_ids' do
    subject { described_class.where(id: [group_1, group_2]).as_ids.pluck(:id) }

    it { is_expected.to contain_exactly(group_1.id, group_2.id) }
  end

  describe '.order_by_depth' do
    subject { described_class.where(id: [group_1, nested_group_1, deep_nested_group_1]).order_by_depth(direction) }

    context 'ascending' do
      let(:direction) { :asc }

      it { is_expected.to eq [deep_nested_group_1, nested_group_1, group_1] }
    end

    context 'descending' do
      let(:direction) { :desc }

      it { is_expected.to eq [group_1, nested_group_1, deep_nested_group_1] }
    end
  end

  describe '.normal_select' do
    let(:query_result) { described_class.where(id: group_1).normal_select }

    subject { query_result.column_names }

    it { is_expected.to eq described_class.column_names }
  end

  shared_examples '.roots' do
    context 'with only sub-groups' do
      subject { described_class.where(id: [deep_nested_group_1, nested_group_1, deep_nested_group_2]).roots }

      it { is_expected.to contain_exactly(group_1, group_2) }
    end

    context 'with only root groups' do
      subject { described_class.where(id: [group_1, group_2]).roots }

      it { is_expected.to contain_exactly(group_1, group_2) }
    end

    context 'with all groups' do
      subject { described_class.where(id: groups).roots }

      it { is_expected.to contain_exactly(group_1, group_2) }
    end
  end

  describe '.roots' do
    it_behaves_like '.roots'

    it 'not make recursive queries' do
      expect { described_class.where(id: [nested_group_1]).roots.load }.not_to make_queries_matching(/WITH RECURSIVE/)
    end
  end

  shared_examples '.self_and_ancestors' do
    subject { described_class.where(id: [nested_group_1, nested_group_2]).self_and_ancestors }

    it { is_expected.to contain_exactly(group_1, nested_group_1, group_2, nested_group_2) }

    context 'when include_self is false' do
      subject { described_class.where(id: [nested_group_1, nested_group_2]).self_and_ancestors(include_self: false) }

      it { is_expected.to contain_exactly(group_1, group_2) }
    end

    context 'when hierarchy_order is ascending' do
      subject { described_class.where(id: [nested_group_1, nested_group_2]).self_and_ancestors(hierarchy_order: :asc) }

      # Recursive order per level is not defined.
      it { is_expected.to contain_exactly(nested_group_1, nested_group_2, group_1, group_2) }
      it { expect(subject[0, 2]).to contain_exactly(nested_group_1, nested_group_2) }
      it { expect(subject[2, 2]).to contain_exactly(group_1, group_2) }
    end

    context 'when hierarchy_order is descending' do
      subject { described_class.where(id: [nested_group_1, nested_group_2]).self_and_ancestors(hierarchy_order: :desc) }

      # Recursive order per level is not defined.
      it { is_expected.to contain_exactly(nested_group_1, nested_group_2, group_1, group_2) }
      it { expect(subject[0, 2]).to contain_exactly(group_1, group_2) }
      it { expect(subject[2, 2]).to contain_exactly(nested_group_1, nested_group_2) }
    end

    context 'with offset and limit' do
      subject { described_class.where(id: [deep_nested_group_1, deep_nested_group_2]).order(:traversal_ids).offset(1).limit(1).self_and_ancestors }

      it { is_expected.to contain_exactly(group_2, nested_group_2, deep_nested_group_2) }
    end

    context 'with upto' do
      subject { described_class.where(id: deep_nested_group_1).self_and_ancestors(upto: nested_group_1.id) }

      it { is_expected.to contain_exactly(deep_nested_group_1) }
    end
  end

  describe '.self_and_ancestors' do
    it_behaves_like '.self_and_ancestors'

    it 'not make recursive queries' do
      expect { described_class.where(id: [nested_group_1]).self_and_ancestors.load }.not_to make_queries_matching(/WITH RECURSIVE/)
    end
  end

  shared_examples '.self_and_ancestor_ids' do
    subject { described_class.where(id: [nested_group_1, nested_group_2]).self_and_ancestor_ids.pluck(:id) }

    it { is_expected.to contain_exactly(group_1.id, nested_group_1.id, group_2.id, nested_group_2.id) }

    context 'when include_self is false' do
      subject do
        described_class
          .where(id: [nested_group_1, nested_group_2])
          .self_and_ancestor_ids(include_self: false)
          .pluck(:id)
      end

      it { is_expected.to contain_exactly(group_1.id, group_2.id) }
    end

    context 'with offset and limit' do
      subject do
        described_class
          .where(id: [deep_nested_group_1, deep_nested_group_2])
          .order(:traversal_ids)
          .limit(1)
          .offset(1)
          .self_and_ancestor_ids
          .pluck(:id)
      end

      it { is_expected.to contain_exactly(group_2.id, nested_group_2.id, deep_nested_group_2.id) }
    end
  end

  describe '.self_and_ancestor_ids' do
    it_behaves_like '.self_and_ancestor_ids'

    it 'not make recursive queries' do
      expect { described_class.where(id: [nested_group_1]).self_and_ancestor_ids.load }.not_to make_queries_matching(/WITH RECURSIVE/)
    end
  end

  shared_examples '.self_and_descendants' do
    subject { described_class.where(id: [nested_group_1, nested_group_2]).self_and_descendants }

    it { is_expected.to contain_exactly(nested_group_1, deep_nested_group_1, nested_group_2, deep_nested_group_2) }

    context 'with duplicate descendants' do
      subject { described_class.where(id: [group_1, group_2, nested_group_1]).self_and_descendants }

      it { is_expected.to match_array(groups) }
    end

    context 'when include_self is false' do
      subject { described_class.where(id: [nested_group_1, nested_group_2]).self_and_descendants(include_self: false) }

      it { is_expected.to contain_exactly(deep_nested_group_1, deep_nested_group_2) }

      context 'with duplicate descendants' do
        subject { described_class.where(id: [group_1, nested_group_1]).self_and_descendants(include_self: false) }

        it { is_expected.to contain_exactly(nested_group_1, deep_nested_group_1) }
      end
    end

    context 'with offset and limit' do
      subject { described_class.where(id: [group_1, group_2]).order(:traversal_ids).offset(1).limit(1).self_and_descendants }

      it { is_expected.to contain_exactly(group_2, nested_group_2, deep_nested_group_2) }
    end

    context 'with nested query groups' do
      let!(:nested_group_1b) { create(:group, parent: group_1) }
      let!(:deep_nested_group_1b) { create(:group, parent: nested_group_1b) }
      let(:group1_hierarchy) { [group_1, nested_group_1, deep_nested_group_1, nested_group_1b, deep_nested_group_1b] }

      subject { described_class.where(id: [group_1, nested_group_1]).self_and_descendants }

      it { is_expected.to match_array group1_hierarchy }
    end
  end

  describe '.self_and_descendants' do
    include_examples '.self_and_descendants'
  end

  shared_examples '.self_and_descendant_ids' do
    subject { described_class.where(id: [nested_group_1, nested_group_2]).self_and_descendant_ids.pluck(:id) }

    it { is_expected.to contain_exactly(nested_group_1.id, deep_nested_group_1.id, nested_group_2.id, deep_nested_group_2.id) }

    context 'when include_self is false' do
      subject do
        described_class
          .where(id: [nested_group_1, nested_group_2])
          .self_and_descendant_ids(include_self: false)
          .pluck(:id)
      end

      it { is_expected.to contain_exactly(deep_nested_group_1.id, deep_nested_group_2.id) }
    end

    context 'with offset and limit' do
      subject do
        described_class
          .where(id: [group_1, group_2])
          .order(:traversal_ids)
          .limit(1)
          .offset(1)
          .self_and_descendant_ids
          .pluck(:id)
      end

      it { is_expected.to contain_exactly(group_2.id, nested_group_2.id, deep_nested_group_2.id) }
    end
  end

  describe '.self_and_descendant_ids' do
    include_examples '.self_and_descendant_ids'
  end

  describe '.self_and_hierarchy' do
    let(:base_scope) { Group.where(id: base_groups) }

    subject { base_scope.self_and_hierarchy }

    context 'with ancestors only' do
      let(:base_groups) { [group_1, group_2] }

      it { is_expected.to match_array(groups) }
    end

    context 'with descendants only' do
      let(:base_groups) { [deep_nested_group_1, deep_nested_group_2] }

      it { is_expected.to match_array(groups) }
    end

    context 'nodes with both ancestors and descendants' do
      let(:base_groups) { [nested_group_1, nested_group_2] }

      it { is_expected.to match_array(groups) }
    end

    context 'with duplicate base groups' do
      let(:base_groups) { [nested_group_1, nested_group_1] }

      it { is_expected.to contain_exactly(group_1, nested_group_1, deep_nested_group_1) }
    end
  end
end
