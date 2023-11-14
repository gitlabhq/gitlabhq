# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Delete a cluster agent', feature_category: :deployment_management do
  include GraphqlHelpers

  let(:cluster_agent) { create(:cluster_agent) }
  let(:project) { cluster_agent.project }
  let(:current_user) { create(:user) }

  let(:mutation) do
    graphql_mutation(
      :cluster_agent_delete,
      { id: cluster_agent.to_global_id.uri }
    )
  end

  def mutation_response
    graphql_mutation_response(:cluster_agent_delete)
  end

  context 'without project permissions' do
    it_behaves_like 'a mutation that returns top-level errors',
      errors: ['The resource that you are attempting to access does not exist '\
        'or you don\'t have permission to perform this action']

    it 'does not delete cluster agent' do
      expect { cluster_agent.reload }.not_to raise_error
    end
  end

  context 'with project permissions' do
    before do
      project.add_maintainer(current_user)
    end

    it 'deletes a cluster agent', :aggregate_failures do
      expect { post_graphql_mutation(mutation, current_user: current_user) }.to change { Clusters::Agent.count }.by(-1)
      expect(mutation_response['errors']).to eq([])
    end
  end
end
