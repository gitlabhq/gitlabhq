# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::NamespaceProjectIdsEachBatch, feature_category: :database do
  let_it_be(:group) { create(:group) }

  let_it_be(:subgroup) { create(:group, parent: group) }

  let_it_be(:subsubgroup1) { create(:group, parent: subgroup) }
  let_it_be(:subsubgroup2) { create(:group, parent: subgroup) }
  let_it_be(:subsubgroup3) { create(:group, parent: subgroup) }

  let_it_be(:project1) { create(:project, namespace: group) }
  let_it_be(:project2) { create(:project, namespace: group) }
  let_it_be(:project3) { create(:project, namespace: subsubgroup2) }
  let_it_be(:project4) { create(:project, namespace: subsubgroup3) }
  let_it_be(:project5) { create(:project, namespace: subsubgroup3) }

  before do
    another_group = create(:group)
    create(:project, namespace: another_group) # This won't be returned
  end

  it 'returns the correct project IDs' do
    expect(
      described_class.new(group_id: group.id).execute
    ).to match_array([project1.id, project2.id, project3.id, project4.id, project5.id])
  end

  context 'when passed an optional resolver' do
    it 'returns the correct project IDs filtered by resolver' do
      resolver = ->(batch) {
        Project.where(id: batch).where(path: [project1.path, project2.path]).pluck_primary_key
      }
      expect(
        described_class.new(group_id: group.id, resolver: resolver).execute
      ).to match_array([project1.id, project2.id])
    end
  end
end
