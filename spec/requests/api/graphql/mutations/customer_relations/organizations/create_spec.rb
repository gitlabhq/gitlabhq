# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'mutation CustomerRelationsOrganizationCreate', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:developer) { create(:user, developer_of: group) }

  let(:current_user) { developer }

  let(:variables) do
    {
      group_id: group.to_global_id.to_s,
      name: 'GitLab'
    }
  end

  let(:mutation) do
    graphql_mutation(:customer_relations_organization_create, variables) do
      <<~QL
        errors
        organization {
          id
          name
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:customer_relations_organization_create) }

  it 'creates the organization', :aggregate_failures do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['errors']).to be_empty
    expect(mutation_response['organization']).to include('name' => 'GitLab')
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :create_crm_organization do
    let(:user) { developer }
    let(:boundary_object) { group }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end
end
