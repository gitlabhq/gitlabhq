# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CatalogResourceDestroy', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :catalog_resource_with_components) }
  let_it_be(:catalog_resource) { create(:ci_catalog_resource, project: project) }

  let(:mutation) do
    variables = {
      project_path: project.full_path
    }
    graphql_mutation(:catalog_resources_destroy, variables,
      <<-QL.strip_heredoc
                      errors
      QL
    )
  end

  context 'when unauthorized' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when authorized' do
    before do
      catalog_resource.project.add_owner(current_user)
    end

    it 'destroys the catalog resource' do
      expect(project.catalog_resource).to eq(catalog_resource)

      post_graphql_mutation(mutation, current_user: current_user)

      expect(project.reload.catalog_resource).to be_nil
      expect_graphql_errors_to_be_empty
    end
  end
end
