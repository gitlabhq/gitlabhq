# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a new cluster agent token', feature_category: :deployment_management do
  include GraphqlHelpers

  let_it_be(:cluster_agent) { create(:cluster_agent) }
  let_it_be(:current_user) { create(:user) }

  let(:description) { 'create token' }
  let(:name) { 'token name' }
  let(:mutation) do
    graphql_mutation(
      :cluster_agent_token_create,
      { cluster_agent_id: cluster_agent.to_global_id.to_s, description: description, name: name }
    )
  end

  def mutation_response
    graphql_mutation_response(:cluster_agent_token_create)
  end

  context 'without user permissions' do
    it_behaves_like 'a mutation that returns top-level errors',
      errors: ["The resource that you are attempting to access does not exist "\
               "or you don't have permission to perform this action"]

    it 'does not create a token' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(Clusters::AgentToken, :count)
    end
  end

  context 'with project permissions' do
    before do
      cluster_agent.project.add_maintainer(current_user)
    end

    it 'creates a new token', :aggregate_failures do
      expect { post_graphql_mutation(mutation, current_user: current_user) }.to change { Clusters::AgentToken.count }.by(1)
      expect(mutation_response['errors']).to eq([])
    end

    it 'returns token information', :aggregate_failures do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['secret']).not_to be_nil
      expect(mutation_response.dig('token', 'description')).to eq(description)
      expect(mutation_response.dig('token', 'name')).to eq(name)
    end
  end
end
