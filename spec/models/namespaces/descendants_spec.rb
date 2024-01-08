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
end
