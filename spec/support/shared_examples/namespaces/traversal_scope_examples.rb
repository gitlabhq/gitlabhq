# frozen_string_literal: true

RSpec.shared_examples 'namespace traversal scopes' do
  # Hierarchy 1
  let_it_be(:group_1) { create(:group) }
  let_it_be(:nested_group_1) { create(:group, parent: group_1) }
  let_it_be(:deep_nested_group_1) { create(:group, parent: nested_group_1) }

  # Hierarchy 2
  let_it_be(:group_2) { create(:group) }
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

  describe '.without_sti_condition' do
    subject { described_class.without_sti_condition }

    it { expect(subject.where_values_hash).not_to have_key(:type) }
  end

  describe '.self_and_descendants' do
    subject { described_class.where(id: [nested_group_1, nested_group_2]).self_and_descendants }

    it { is_expected.to contain_exactly(nested_group_1, deep_nested_group_1, nested_group_2, deep_nested_group_2) }

    context 'with duplicate descendants' do
      subject { described_class.where(id: [group_1, group_2, nested_group_1]).self_and_descendants }

      it { is_expected.to match_array(groups) }
    end

    context 'when include_self is false' do
      subject { described_class.where(id: [nested_group_1, nested_group_2]).self_and_descendants(include_self: false) }

      it { is_expected.to contain_exactly(deep_nested_group_1, deep_nested_group_2) }
    end
  end

  describe '.self_and_descendant_ids' do
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
  end
end
