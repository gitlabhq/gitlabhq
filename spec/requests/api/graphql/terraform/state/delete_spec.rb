# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'delete a terraform state', feature_category: :infrastructure_as_code do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  let(:state) { create(:terraform_state, project: project) }
  let(:mutation) { graphql_mutation(:terraform_state_delete, id: state.to_global_id.to_s) }

  it_behaves_like 'authorizing granular token permissions for GraphQL', :delete_terraform_state do
    let(:boundary_object) { project }
    let(:mutation) { graphql_mutation(:terraform_state_delete, id: state.to_global_id.to_s) }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }

    before do
      allow_next_instance_of(Terraform::States::TriggerDestroyService) do |service|
        allow(service).to receive(:execute).and_return(ServiceResponse.success)
      end
    end
  end

  before do
    expect_next_instance_of(Terraform::States::TriggerDestroyService, state, current_user: user) do |service|
      expect(service).to receive(:execute).once.and_return(ServiceResponse.success)
    end

    post_graphql_mutation(mutation, current_user: user)
  end

  include_examples 'a working graphql query'
end
