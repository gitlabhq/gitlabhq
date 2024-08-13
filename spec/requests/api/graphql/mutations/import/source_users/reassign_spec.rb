# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Reassign an import source user', feature_category: :importers do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:assignee_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:import_source_user) { create(:import_source_user, namespace: group) }

  let(:variables) do
    {
      id: import_source_user.to_global_id,
      assignee_user_id: assignee_user.to_global_id
    }
  end

  let(:mutation) do
    graphql_mutation(:import_source_user_reassign, variables) do
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

  let(:mutation_response) { graphql_mutation_response(:import_source_user_reassign) }

  context 'when user is authorized' do
    before_all do
      group.add_owner(current_user)
    end

    it 'reassign import source user', :aggregate_failures do
      expect(Notify).to receive_message_chain(:import_source_user_reassign, :deliver_now)

      post_graphql_mutation(mutation, current_user: current_user)

      import_source_user = mutation_response['importSourceUser']

      expect(import_source_user['reassignToUser']['id']).to eq(global_id_of(assignee_user).to_s)
      expect(import_source_user['reassignedByUser']['id']).to eq(global_id_of(current_user).to_s)
      expect(import_source_user['status']).to eq('AWAITING_APPROVAL')
    end

    context 'when the reassign fails' do
      let(:assignee_user) { create(:user, :bot) }

      it 'returns the reason and does not change import source user status', :aggregate_failures do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['errors']).to be_present
        expect(mutation_response['importSourceUser']['status']).to eq('PENDING_REASSIGNMENT')
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
