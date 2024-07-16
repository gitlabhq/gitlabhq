# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resend notification to the reassigned user of an import source user', feature_category: :importers do
  include GraphqlHelpers

  let_it_be(:owner) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:group) { create(:group) }
  let(:current_user) { owner }
  let(:import_source_user) { create(:import_source_user, :awaiting_approval, namespace: group) }

  let(:variables) do
    {
      id: import_source_user.to_global_id
    }
  end

  let(:mutation) do
    graphql_mutation(:import_source_user_resend_notification, variables) do
      <<~QL
        clientMutationId
        errors
        importSourceUser {
          reassignToUser {
            id
          }
          status
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:import_source_user_resend_notification) }

  before_all do
    group.add_owner(owner)
    group.add_maintainer(maintainer)
  end

  context 'when user is authorized' do
    it 'resends notification and does not change status', :aggregate_failures do
      expect(Notify).to receive_message_chain(:import_source_user_reassign, :deliver_now)

      post_graphql_mutation(mutation, current_user: current_user)

      import_source_user = mutation_response['importSourceUser']

      expect(import_source_user['status']).to eq('AWAITING_APPROVAL')
    end
  end

  context 'when user is not authorized' do
    let(:current_user) { maintainer }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when the request is rate limited' do
    it 'returns an error' do
      expect(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)

      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors).to contain_exactly(
        hash_including(
          'message' => 'This endpoint has been requested too many times. Try again later.'
        )
      )
    end
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
