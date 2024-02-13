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

    it 'up to date descendant record for a group' do
      descendants = create(:namespace_descendants, namespace: group)

      expect(descendants).to have_attributes(
        self_and_descendant_group_ids: [group.id, subgroup.id],
        all_project_ids: [project1.id, project2.id],
        traversal_ids: [group.id]
      )
    end

    it 'creates up-to-date descendant record for a subgroup' do
      descendants = create(:namespace_descendants, namespace: subgroup)

      expect(descendants).to have_attributes(
        self_and_descendant_group_ids: [subgroup.id],
        all_project_ids: [project1.id],
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
    let_it_be(:cache) { create(:namespace_descendants, :outdated, calculated_at: nil, traversal_ids: [100, 200]) }

    it 'updates the namespace descendant record', :freeze_time do
      described_class.upsert_with_consistent_data(
        namespace: cache.namespace,
        self_and_descendant_group_ids: [1, 2, 3],
        all_project_ids: [5, 6, 7]
      )

      cache.reload

      expect(cache).to have_attributes(
        traversal_ids: cache.namespace.traversal_ids,
        self_and_descendant_group_ids: [1, 2, 3],
        all_project_ids: [5, 6, 7],
        outdated_at: nil,
        calculated_at: Time.current
      )
    end
  end
end
