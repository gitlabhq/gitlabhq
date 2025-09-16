# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Undo keep as placeholder reassignment of an import source user', feature_category: :importers do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:import_source_user) do
    create(:import_source_user, :keep_as_placeholder, reassigned_by_user: current_user, namespace: group)
  end

  let(:variables) do
    {
      id: import_source_user.to_global_id
    }
  end

  let(:mutation) do
    graphql_mutation(:import_source_user_undo_keep_as_placeholder, variables) do
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

  let(:mutation_response) { graphql_mutation_response(:import_source_user_undo_keep_as_placeholder) }

  context 'when user is authorized' do
    before_all do
      group.add_owner(current_user)
    end

    it 'sets import user source status back to pending_reassignment', :aggregate_failures do
      post_graphql_mutation(mutation, current_user: current_user)

      import_source_user = mutation_response['importSourceUser']

      expect(import_source_user['reassignedToUser']).to be_nil
      expect(import_source_user['reassignedByUser']).to be_nil
      expect(import_source_user['status']).to eq('PENDING_REASSIGNMENT')
    end

    context 'when operation fails' do
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
end
