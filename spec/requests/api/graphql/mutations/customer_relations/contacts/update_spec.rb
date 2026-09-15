# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'mutation CustomerRelationsContactUpdate', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:developer) { create(:user, developer_of: group) }

  let(:current_user) { developer }
  let(:contact) { create(:contact, group: group) }

  let(:variables) do
    {
      id: contact.to_global_id.to_s,
      first_name: 'Lionel',
      last_name: 'Smith'
    }
  end

  let(:mutation) do
    graphql_mutation(:customer_relations_contact_update, variables) do
      <<~QL
        errors
        contact {
          id
          firstName
          lastName
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:customer_relations_contact_update) }

  it 'updates the contact', :aggregate_failures do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['errors']).to be_empty
    expect(mutation_response['contact']).to include(
      'id' => contact.to_global_id.to_s,
      'firstName' => 'Lionel',
      'lastName' => 'Smith'
    )
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :update_crm_contact do
    let(:user) { developer }
    let(:boundary_object) { group }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end
end
