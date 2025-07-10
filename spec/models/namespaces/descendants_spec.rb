# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Descendants, feature_category: :database do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    subject(:namespace_descendants) { create(:namespace_descendants) }

    it { is_expected.to validate_uniqueness_of(:namespace_id) }
  end

  describe 'factory' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }

    let_it_be(:project1) { create(:project, group: subgroup) }
    let_it_be(:project2) { create(:project, group: group) }
    let_it_be(:project3) { create(:project, group: group, archived: true) }

    it 'up to date descendant record for a group' do
      descendants = create(:namespace_descendants, namespace: group)

      expect(descendants).to have_attributes(
        self_and_descendant_group_ids: [group.id, subgroup.id],
        all_project_ids: [project1.id, project2.id, project3.id],
        all_unarchived_project_ids: [project1.id, project2.id],
        traversal_ids: [group.id]
      )
    end

    it 'creates up-to-date descendant record for a subgroup' do
      descendants = create(:namespace_descendants, namespace: subgroup)

      expect(descendants).to have_attributes(
        self_and_descendant_group_ids: [subgroup.id],
        all_project_ids: [project1.id],
        all_unarchived_project_ids: [project1.id],
        traversal_ids: [group.id, subgroup.id]
      )
    end
  end

  describe '.expire_for' do
    it 'sets the outdated_at column for the given namespace ids' do
      freeze_time do
        expire_time = Time.current

        group1 = create(:group).tap do |g|
          create(:namespace_descendants, namespace: g).reload.update!(outdated_at: nil)
        end
        group2 = create(:group, parent: group1).tap { |g| create(:namespace_descendants, namespace: g) }
        group3 = create(:group, parent: group1)

        group4 = create(:group).tap do |g|
          create(:namespace_descendants, namespace: g).reload.update!(outdated_at: nil)
        end

        described_class.expire_for([group1.id, group2.id, group3.id])

        expect(group1.namespace_descendants.outdated_at).to eq(expire_time)
        expect(group2.namespace_descendants.outdated_at).to eq(expire_time)
        expect(group3.namespace_descendants).to be_nil
        expect(group4.namespace_descendants.outdated_at).to be_nil
      end
    end
  end

  describe '.expire_recursive_for' do
    it 'sets the outdated_at column for app parents and children of the given namespace' do
      freeze_time do
        expire_time = Time.current

        # given this group tree:
        # root_group/
        #   l1_group1/
        #     l2_group1/
        #     l2_group2/
        #       l3_group1/
        #   l1_group2/
        #     l2_group3
        # with l2_group2 as input, the following needs to be expired:
        # root_group, l1_group1, l2_group2, and l3_group1
        # These groups should be left unchanged:
        # l2_group1, l1_group2, and l2_group3

        root_group = create(:group).tap { |g| create(:namespace_descendants, namespace: g) }
        l1_group1 = create(:group, parent: root_group).tap { |g| create(:namespace_descendants, namespace: g) }
        l2_group1 = create(:group, parent: l1_group1).tap { |g| create(:namespace_descendants, namespace: g) }
        l2_group2 = create(:group, parent: l1_group1).tap { |g| create(:namespace_descendants, namespace: g) }
        l3_group1 = create(:group, parent: l2_group2).tap { |g| create(:namespace_descendants, namespace: g) }
        l1_group2 = create(:group, parent: root_group).tap { |g| create(:namespace_descendants, namespace: g) }
        l2_group3 = create(:group, parent: l1_group2).tap { |g| create(:namespace_descendants, namespace: g) }

        # nil-ifying the descendants only after they are all created
        Namespaces::Descendants.update_all(outdated_at: nil)

        described_class.expire_recursive_for(l2_group2)

        expect(root_group.namespace_descendants.outdated_at).to eq(expire_time)
        expect(l1_group1.namespace_descendants.outdated_at).to eq(expire_time)
        expect(l2_group2.namespace_descendants.outdated_at).to eq(expire_time)
        expect(l3_group1.namespace_descendants.outdated_at).to eq(expire_time)

        expect(l2_group1.namespace_descendants.outdated_at).to be_nil
        expect(l1_group2.namespace_descendants.outdated_at).to be_nil
        expect(l2_group3.namespace_descendants.outdated_at).to be_nil
      end
    end
  end

  describe '.load_outdated_batch' do
    let_it_be(:cache1) { create(:namespace_descendants, :outdated) }
    let_it_be(:cache2) { create(:namespace_descendants, :up_to_date) }
    let_it_be(:cache3) { create(:namespace_descendants, :outdated) }
    let_it_be(:cache4) { create(:namespace_descendants, :outdated) }
    let_it_be(:cache5) { create(:namespace_descendants, :up_to_date) }

    it 'returns outdated namespace_descendants ids' do
      ids = described_class.load_outdated_batch(2)

      expect(ids.size).to eq(2)
      expect([cache1.namespace_id, cache3.namespace_id, cache4.namespace_id]).to include(*ids)

      expect(described_class.load_outdated_batch(10)).to match_array([cache1.namespace_id, cache3.namespace_id,
        cache4.namespace_id])
    end
  end

  describe '.upsert_with_consistent_data' do
    let_it_be_with_reload(:cache) do
      create(:namespace_descendants, :outdated, calculated_at: nil, traversal_ids: [100, 200])
    end

    it 'updates the namespace descendant record', :freeze_time do
      described_class.upsert_with_consistent_data(
        namespace: cache.namespace,
        self_and_descendant_group_ids: [1, 2, 3],
        all_project_ids: [5, 6, 7],
        all_unarchived_project_ids: [5, 6]
      )

      cache.reload

      expect(cache).to have_attributes(
        traversal_ids: cache.namespace.traversal_ids,
        self_and_descendant_group_ids: [1, 2, 3],
        all_project_ids: [5, 6, 7],
        all_unarchived_project_ids: [5, 6],
        outdated_at: nil,
        calculated_at: Time.current
      )
    end

    describe 'setting outdated_at for optimistic locking' do
      context 'when outdated_at value changed in the meantime' do
        it 'keeps the outdated_at value set thus the record stays outdated' do
          outdated_at = cache.outdated_at
          new_outdated_at_value = outdated_at + 1.day

          cache.update!(outdated_at: new_outdated_at_value)

          described_class.upsert_with_consistent_data(
            namespace: cache.namespace,
            self_and_descendant_group_ids: [1, 2, 3],
            all_project_ids: [5, 6, 7],
            all_unarchived_project_ids: [5, 6],
            outdated_at: outdated_at
          )

          cache.reload

          expect(cache.outdated_at).to eq(new_outdated_at_value)
        end
      end

      context 'when outdated_at value did not change' do
        it 'marks the record up to date' do
          cache.reload

          described_class.upsert_with_consistent_data(
            namespace: cache.namespace,
            self_and_descendant_group_ids: [1, 2, 3],
            all_project_ids: [5, 6, 7],
            all_unarchived_project_ids: [5, 6],
            outdated_at: cache.outdated_at
          )

          cache.reload

          expect(cache.outdated_at).to be_nil
        end
      end
    end
  end
end
