# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Cancel an reassignment of an import source user', feature_category: :importers do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:import_source_user) do
    create(:import_source_user, :awaiting_approval,
      reassign_to_user: current_user, reassigned_by_user: current_user, namespace: group
    )
  end

  let(:variables) do
    {
      id: import_source_user.to_global_id
    }
  end

  let(:mutation) do
    graphql_mutation(:import_source_user_cancel_reassignment, variables) do
      <<~QL
        clientMutationId
        errors
        importSourceUser {
          reassignToUser {
            id
          }
          reassignedByUser {
            id
          }
          status
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:import_source_user_cancel_reassignment) }

  context 'when user is authorized' do
    before_all do
      group.add_owner(current_user)
    end

    it 'sets import user source status back to pending_reassignment', :aggregate_failures do
      post_graphql_mutation(mutation, current_user: current_user)

      import_source_user = mutation_response['importSourceUser']

      expect(import_source_user['reassignedToUser']).to eq(nil)
      expect(import_source_user['reassignedByUser']).to eq(nil)
      expect(import_source_user['status']).to eq('PENDING_REASSIGNMENT')
    end

    context 'when cancelation fails' do
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
