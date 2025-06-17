# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'projects_with_variables_query' do
  describe '.projects_with_variables' do
    let_it_be(:project1) { create(:project) }
    let_it_be(:project2) { create(:project) }
    let_it_be(:project3) { create(:project) }
    let_it_be(:project4) { create(:project) }

    let(:project_ids) { [project1.id, project2.id, project3.id, project4.id] }

    before do
      # Create variables for some projects
      create_variable(project1)
      create_variable(project1) # Multiple variables for same project
      create_variable(project3)
      # project2 and project4 have no variables
    end

    context 'when projects have variables' do
      it 'returns project IDs that have variables' do
        result = described_class.projects_with_variables(project_ids, 10)

        expect(result).to match_array([project1.id, project3.id])
      end
    end

    context 'when no projects have variables' do
      let(:empty_project_ids) { [project2.id, project4.id] }

      it 'returns empty array' do
        result = described_class.projects_with_variables(empty_project_ids, 10)

        expect(result).to be_empty
      end
    end

    context 'when project_ids contains non-existent project IDs' do
      let(:mixed_project_ids) { [project1.id, project4.id + 1, project3.id, project4.id + 2] }

      it 'only returns existing project IDs that have variables' do
        result = described_class.projects_with_variables(mixed_project_ids, 10)

        expect(result).to match_array([project1.id, project3.id])
      end
    end

    context 'with limit parameter' do
      it 'respects the limit when more projects than limit have variables' do
        result = described_class.projects_with_variables(project_ids, 1)

        expect(result.size).to eq(1)
      end

      it 'returns all matching projects when limit is higher than matches' do
        result = described_class.projects_with_variables(project_ids, 10)

        expect(result).to match_array([project1.id, project3.id])
      end
    end
  end
end
