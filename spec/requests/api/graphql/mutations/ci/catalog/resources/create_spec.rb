# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CatalogResourcesCreate', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :catalog_resource_with_components) }

  let(:mutation) do
    variables = {
      project_path: project.full_path
    }
    graphql_mutation(:catalog_resources_create, variables,
      <<-QL.strip_heredoc
                      errors
      QL
    )
  end

  context 'when unauthorized' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when authorized' do
    before_all do
      project.add_owner(current_user)
    end

    context 'with a valid project' do
      it 'creates a catalog resource' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_mutation_response(:catalog_resources_create)['errors']).to be_empty
        expect(response).to have_gitlab_http_status(:success)
      end
    end

    it_behaves_like 'authorizing granular token permissions for GraphQL', :create_catalog_resource do
      let(:user) { current_user }
      let(:boundary_object) { project }
      let(:mutation) do
        graphql_mutation(:catalog_resources_create, { project_path: project.full_path }, 'errors')
      end

      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end
  end
end
