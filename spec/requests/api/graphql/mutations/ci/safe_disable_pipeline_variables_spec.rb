# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SafeDisablePipelineVariables', feature_category: :ci_variables do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:variables) do
    {
      full_path: group.full_path
    }
  end

  let(:mutation) { graphql_mutation(:safe_disable_pipeline_variables, variables, 'success errors') }

  subject(:request) { post_graphql_mutation(mutation, current_user: user) }

  context 'when unauthorized' do
    shared_examples 'returns authorization error' do
      it 'returns GraphQL authorization error' do
        request

        expect(graphql_mutation_response(:safe_disable_pipeline_variables)).to be_nil
        expect(graphql_errors).to include(
          hash_including(
            'message' => "The resource that you are attempting to access does not exist " \
              "or you don't have permission to perform this action"
          )
        )
      end
    end

    context 'when not a group member' do
      it_behaves_like 'returns authorization error'
    end

    context 'when a non-admin group member' do
      before_all do
        group.add_maintainer(user)
      end

      it_behaves_like 'returns authorization error'
    end
  end

  context 'when authorized' do
    before_all do
      group.add_owner(user)
    end

    it 'enqueues the worker and returns success' do
      expect(::Ci::SafeDisablePipelineVariablesWorker).to receive(:perform_async).with(user.id, group.id)

      request

      expect(graphql_mutation_response(:safe_disable_pipeline_variables)['success']).to be true
      expect(graphql_mutation_response(:safe_disable_pipeline_variables)['errors']).to be_empty
      expect(graphql_errors).to be_nil
    end

    context 'when bad arguments are provided' do
      let(:variables) { { full_path: 'non-existent-group' } }

      it 'returns GraphQL authorization error for non-existent group' do
        request

        expect(graphql_mutation_response(:safe_disable_pipeline_variables)).to be_nil
        expect(graphql_errors).to include(
          hash_including(
            'message' => "The resource that you are attempting to access does not exist " \
              "or you don't have permission to perform this action"
          )
        )
      end
    end

    context 'when request is made to a namespace instead of a group' do
      let_it_be(:namespace) { create(:namespace) }

      let(:variables) do
        {
          full_path: namespace.full_path
        }
      end

      it 'returns GraphQL authorization error for namespace' do
        post_graphql_mutation(mutation, current_user: namespace.owner)

        expect(graphql_mutation_response(:safe_disable_pipeline_variables)).to be_nil
        expect(graphql_errors).to include(
          hash_including(
            'message' => "The resource that you are attempting to access does not exist " \
              "or you don't have permission to perform this action"
          )
        )
      end
    end
  end
end
