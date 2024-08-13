# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Keep as placeholder an import source user', feature_category: :importers do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:import_source_user) { create(:import_source_user, namespace: group) }

  let(:variables) do
    {
      id: import_source_user.to_global_id
    }
  end

  let(:mutation) do
    graphql_mutation(:import_source_user_keep_as_placeholder, variables) do
      <<~QL
        clientMutationId
        errors
        importSourceUser {
          reassignedByUser {
            id
          }
          status
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:import_source_user_keep_as_placeholder) }

  context 'when user is authorized' do
    before_all do
      group.add_owner(current_user)
    end

    it 'sets import source as keep_as_placeholder', :aggregate_failures do
      post_graphql_mutation(mutation, current_user: current_user)

      import_source_user = mutation_response['importSourceUser']

      expect(import_source_user['reassignedByUser']['id']).to eq(current_user.to_global_id.to_s)
      expect(import_source_user['status']).to eq('KEEP_AS_PLACEHOLDER')
    end

    context 'when setting as keep_as_placeholder fails' do
      let(:import_source_user) { create(:import_source_user, :completed, namespace: group) }

      it 'returns the reason and does not change import source user status', :aggregate_failures do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['errors']).to be_present
        expect(mutation_response['importSourceUser']['status']).to eq('COMPLETED')
      end
    end
  end

  context 'when user is not authorized' do
    before_all do
      group.add_maintainer(current_user)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when feature flag `importer_user_mapping`` disabled' do
    before do
      stub_feature_flags(importer_user_mapping: false)
    end

    it 'returns a resource not available error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors).to contain_exactly(
        hash_including(
          'message' => '`importer_user_mapping` feature flag is disabled.'
        )
      )
    end
  end
end
