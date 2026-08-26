# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'mutation CustomerRelationsOrganizationUpdate', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:developer) { create(:user, developer_of: group) }

  let(:current_user) { developer }
  let(:crm_organization) { create(:crm_organization, group: group) }

  let(:variables) do
    {
      id: crm_organization.to_global_id.to_s,
      name: 'GitLab'
    }
  end

  let(:mutation) do
    graphql_mutation(:customer_relations_organization_update, variables) do
      <<~QL
        errors
        organization {
          id
          name
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:customer_relations_organization_update) }

  it 'updates the organization', :aggregate_failures do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['errors']).to be_empty
    expect(mutation_response['organization']).to include(
      'id' => crm_organization.to_global_id.to_s,
      'name' => 'GitLab'
    )
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :update_crm_organization do
    let(:user) { developer }
    let(:boundary_object) { group }
    # Errors-only selection: CustomerRelationsOrganization has no granular
    # directive yet (read permissions land with the type backfill), so the
    # payload's non-nullable organization field is redacted for granular
    # tokens and would error on any successful mutation.
    let(:mutation) { graphql_mutation(:customer_relations_organization_update, variables, 'errors') }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end
end
