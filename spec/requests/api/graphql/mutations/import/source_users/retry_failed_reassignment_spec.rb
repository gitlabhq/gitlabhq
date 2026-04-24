# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Retry failed reassignment of an import source user', feature_category: :importers do
  include GraphqlHelpers

  let_it_be(:owner) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:group) { create(:group) }
  let(:current_user) { owner }
  let(:import_source_user) { create(:import_source_user, :failed, namespace: group) }

  let(:variables) do
    {
      id: import_source_user.to_global_id
    }
  end

  let(:mutation) do
    graphql_mutation(:import_source_user_retry_failed_reassignment, variables) do
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

  let(:mutation_response) { graphql_mutation_response(:import_source_user_retry_failed_reassignment) }

  before_all do
    group.add_owner(owner)
    group.add_maintainer(maintainer)
  end

  context 'when user is authorized' do
    it 'retries the failed reassignment', :aggregate_failures do
      expect(Import::ReassignPlaceholderUserRecordsWorker).to receive(:perform_async).with(import_source_user.id)

      post_graphql_mutation(mutation, current_user: current_user)

      import_source_user = mutation_response['importSourceUser']

      expect(import_source_user['status']).to eq('REASSIGNMENT_IN_PROGRESS')
    end

    context 'when retry attempts have been exceeded', :clean_gitlab_redis_shared_state do
      let(:retry_attempts_key) do
        format(
          Import::SourceUsers::RetryFailedReassignmentService::RETRY_ATTEMPTS_KEY,
          source_user_id: import_source_user.id
        )
      end

      before do
        Import::SourceUsers::RetryFailedReassignmentService::MAX_RETRY_ATTEMPTS.times do |i|
          Gitlab::Cache::Import::Caching.set_add(
            retry_attempts_key,
            (10.hours.ago + i.hours).to_i,
            timeout: Import::SourceUsers::RetryFailedReassignmentService::RETRY_COOLDOWN
          )
        end
      end

      it 'returns an error and does not change the source user status', :aggregate_failures do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['errors']).to contain_exactly(
          'Reassignment retry has failed multiple times. ' \
            'Repeated failures suggest an unexpected error that may need time to resolve. ' \
            'Please try again in about 6 hours.'
        )
        expect(mutation_response['importSourceUser']).to be_nil
      end
    end
  end

  context 'when user is not authorized' do
    let(:current_user) { maintainer }

    it_behaves_like 'a mutation that returns a top-level access error'
  end
end
