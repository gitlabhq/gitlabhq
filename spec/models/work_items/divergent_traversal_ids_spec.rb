# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DivergentTraversalIds, feature_category: :portfolio_management do
  let_it_be(:divergent_project) { create(:project) }
  let_it_be(:divergent_namespace) { divergent_project.project_namespace }
  let_it_be(:divergent_work_item) do
    create(:work_item, project: divergent_project).tap do |work_item|
      work_item.update_column(:namespace_traversal_ids, [-1])
    end
  end

  let_it_be(:aligned_project) { create(:project) }
  let_it_be(:aligned_namespace) { aligned_project.project_namespace }
  let_it_be(:aligned_work_item) { create(:work_item, project: aligned_project) }

  let_it_be(:empty_namespace) { create(:group) }

  describe '.among' do
    it 'returns only the namespaces whose oldest work item diverges' do
      ids = [divergent_namespace.id, aligned_namespace.id, empty_namespace.id]

      expect(described_class.among(ids)).to contain_exactly(divergent_namespace.id)
    end

    it 'excludes namespaces with no issues' do
      expect(described_class.among([empty_namespace.id])).to be_empty
    end

    it 'returns an empty array when given no ids' do
      expect(described_class.among([])).to eq([])
    end
  end
end
