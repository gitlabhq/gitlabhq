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
end
