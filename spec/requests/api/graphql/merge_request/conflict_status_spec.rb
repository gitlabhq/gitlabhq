# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.mergeRequest.conflictStatus', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  let(:current_user) { developer }
  let(:conflict_status_data) { graphql_data_at(:merge_request, :conflict_status) }
  let(:merge_request_params) { { 'id' => global_id_of(merge_request) } }

  let(:query) do
    graphql_query_for('mergeRequest', merge_request_params, 'conflictStatus')
  end

  subject(:post_query) { post_graphql(query, current_user: current_user) }

  context 'when the merge request has conflicts' do
    let_it_be(:merge_request) do
      create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start',
        source_project: project, merge_status: :cannot_be_merged)
    end

    before do
      ::MergeRequests::MergeabilityCheckService.new(merge_request).execute
    end

    context 'when the current user can push to the source branch' do
      it 'returns HAS_CONFLICTS' do
        post_query

        expect(conflict_status_data).to eq('HAS_CONFLICTS')
      end
    end

    context 'when the current user cannot push to the source branch' do
      let(:current_user) { reporter }

      it 'returns NO_PUSH_ACCESS' do
        post_query

        expect(conflict_status_data).to eq('NO_PUSH_ACCESS')
      end
    end
  end

  context 'when mergeability has not been determined yet' do
    let_it_be(:merge_request) do
      create(:merge_request, source_project: project, target_project: project, merge_status: :unchecked)
    end

    it 'returns UNCHECKED' do
      post_query

      expect(conflict_status_data).to eq('UNCHECKED')
    end
  end

  context 'when the merge request can be merged' do
    let_it_be(:merge_request) do
      create(:merge_request, source_project: project, target_project: project, merge_status: :can_be_merged)
    end

    it 'returns NO_CONFLICTS' do
      post_query

      expect(conflict_status_data).to eq('NO_CONFLICTS')
    end
  end

  context 'when branches or diff refs are unavailable' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:merge_request) do
      create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start',
        source_project: project, merge_status: :cannot_be_merged)
    end

    where(:stubbed_method, :stub_value) do
      :branch_missing?          | true
      :has_complete_diff_refs?  | false
    end

    with_them do
      before do
        allow_next_found_instance_of(MergeRequest) do |mr|
          allow(mr).to receive(stubbed_method).and_return(stub_value)
        end
      end

      it 'returns BRANCH_MISSING' do
        post_query

        expect(conflict_status_data).to eq('BRANCH_MISSING')
      end
    end
  end

  context 'when the merge status is cannot_be_merged_recheck' do
    let_it_be(:merge_request) do
      create(:merge_request, source_project: project, target_project: project,
        merge_status: :cannot_be_merged_recheck)
    end

    it 'returns UNCHECKED' do
      post_query

      expect(conflict_status_data).to eq('UNCHECKED')
    end
  end
end
