# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Revoke the reassignment of an import source user', feature_category: :importers do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:import_source_user) do
    create(:import_source_user, :completed, reassign_to_user: current_user, namespace: group)
  end

  let(:variables) do
    {
      id: import_source_user.to_global_id
    }
  end

  let(:mutation) do
    graphql_mutation(:import_source_user_revoke, variables) do
      <<~QL
        clientMutationId
        errors
        importSourceUser {
          status
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:import_source_user_revoke) }

  context 'when user is the user contributions were reassigned to' do
    it 'revokes the reassignment', :aggregate_failures do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['errors']).to be_empty
      expect(mutation_response['importSourceUser']['status']).to eq('REVOKED')
    end

    it_behaves_like 'authorizing granular token permissions for GraphQL', :revoke_placeholder_reassignment do
      let(:user) { current_user }
      let(:boundary_object) { :user }
      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end

    context 'when the import source user is not completed' do
      let(:import_source_user) do
        create(:import_source_user, :awaiting_approval, reassign_to_user: current_user, namespace: group)
      end

      it 'returns a top-level access error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors.first['message']).to include(
          Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
        )
      end
    end

    context 'when the import source user is already revoked' do
      let(:import_source_user) do
        create(:import_source_user, :revoked, reassign_to_user: current_user, namespace: group)
      end

      it 'returns an error', :aggregate_failures do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['errors']).to include(
          'Import source user has an invalid status for this operation'
        )
        expect(mutation_response['importSourceUser']['status']).to eq('REVOKED')
      end
    end

    context 'when revoke_import_source_user_reassignment feature flag is disabled' do
      before do
        stub_feature_flags(revoke_import_source_user_reassignment: false)
      end

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors.first['message'])
          .to include('`revoke_import_source_user_reassignment` feature flag is disabled.')
      end
    end
  end

  context 'when user is an owner of the namespace' do
    let_it_be(:owner) { create(:user) }

    before_all do
      group.add_owner(owner)
    end

    it 'returns a top-level access error and does not change import source user status', :aggregate_failures do
      post_graphql_mutation(mutation, current_user: owner)

      expect(graphql_errors.first['message']).to include(
        Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
      )
      expect(import_source_user.reload.completed?).to be(true)
    end
  end

  context 'when user is not the user contributions were reassigned to' do
    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: create(:user))

      expect(graphql_errors.first['message']).to include(
        Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
      )
    end
  end
end
