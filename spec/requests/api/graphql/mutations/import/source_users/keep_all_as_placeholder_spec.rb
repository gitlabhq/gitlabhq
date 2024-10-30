# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Keep all import source users in a namespace as placeholders', feature_category: :importers do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:variables) do
    {
      namespace_id: group.to_global_id
    }
  end

  let(:mutation) do
    graphql_mutation(:import_source_user_keep_all_as_placeholder, variables) do
      <<~QL
        clientMutationId
        errors
        updatedImportSourceUserCount
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:import_source_user_keep_all_as_placeholder) }

  context 'when user is authorized', :aggregate_failures do
    let!(:source_user_pending_assignment_1) do
      create(:import_source_user, :pending_reassignment, namespace: group, source_hostname: 'https://gitea.com')
    end

    let!(:source_user_pending_assignment_2) { create(:import_source_user, :pending_reassignment, namespace: group) }
    let!(:source_user_rejected) { create(:import_source_user, :rejected, namespace: group) }
    let!(:source_user_awaiting_approval) { create(:import_source_user, :awaiting_approval, namespace: group) }

    before_all do
      group.add_owner(current_user)
    end

    it 'sets all reassignable source users to keep_as_placeholder' do
      post_graphql_mutation(mutation, current_user: current_user)

      updated_import_source_user_count = mutation_response['updatedImportSourceUserCount']

      expect(updated_import_source_user_count).to eq(3)
      expect(
        [
          source_user_pending_assignment_1,
          source_user_pending_assignment_2,
          source_user_rejected,
          source_user_awaiting_approval
        ].map { |su| su.reload.keep_as_placeholder? }
      ).to eq([true, true, true, false])
    end

    it 'returns 0 when no source users are reassignable' do
      group.import_source_users.update_all(status: Import::SourceUser::STATUSES[:keep_as_placeholder])

      post_graphql_mutation(mutation, current_user: current_user)

      updated_import_source_user_count = mutation_response['updatedImportSourceUserCount']

      expect(updated_import_source_user_count).to eq(0)
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
