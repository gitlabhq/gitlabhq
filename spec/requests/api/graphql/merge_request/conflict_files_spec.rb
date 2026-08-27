# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.mergeRequest.conflictFiles', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  let(:current_user) { developer }
  let(:conflict_files_data) { graphql_data_at(:merge_request, :conflict_files) }
  let(:merge_request_params) { { 'id' => global_id_of(merge_request) } }

  let(:conflict_files_fields) do
    <<~GRAPHQL
      conflictFiles {
        ourPath
        theirPath
        content
      }
    GRAPHQL
  end

  let(:query) do
    graphql_query_for('mergeRequest', merge_request_params, conflict_files_fields)
  end

  subject(:post_query) { post_graphql(query, current_user: current_user) }

  context 'when the merge request has conflicts' do
    let_it_be(:merge_request) do
      create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start',
        source_project: project, merge_status: :cannot_be_merged)
    end

    before do
      ::MergeRequests::MergeabilityCheckService.new(merge_request).execute
      post_query
    end

    context 'when the current user can push to the source branch' do
      it 'returns the conflicting files with raw conflict markers', :aggregate_failures do
        expect(conflict_files_data).to be_present

        expect(conflict_files_data.pluck('ourPath')).to all(be_present)

        contents = conflict_files_data.pluck('content').join("\n")
        expect(contents).to include('<<<<<<').and include('======').and include('>>>>>>')
      end
    end

    context 'when the current user cannot push to the source branch' do
      let(:current_user) { reporter }

      it 'returns null without exposing conflict content' do
        expect(conflict_files_data).to be_nil
      end
    end

    it_behaves_like 'authorizing granular token permissions for GraphQL', :read_merge_request do
      let(:user) { developer }
      let(:boundary_object) { project }
      let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
    end
  end

  context 'when the conflict is a file edited in one branch and deleted in another' do
    let_it_be(:merge_request) do
      create(:merge_request, source_branch: 'conflict-missing-side', target_branch: 'conflict-start',
        source_project: project, merge_status: :cannot_be_merged)
    end

    before do
      ::MergeRequests::MergeabilityCheckService.new(merge_request).execute
      post_query
    end

    it 'returns the conflict file with content', :aggregate_failures do
      expect(conflict_files_data).to be_present
      expect(conflict_files_data.first).to include('ourPath' => be_present, 'content' => be_present)
    end
  end

  context 'when mergeability has not been determined yet' do
    let_it_be(:merge_request) do
      create(:merge_request, source_project: project, target_project: project, merge_status: :unchecked)
    end

    before do
      post_query
    end

    it 'returns null' do
      expect(conflict_files_data).to be_nil
    end
  end

  context 'when the merge request can be merged' do
    let_it_be(:merge_request) do
      create(:merge_request, source_project: project, target_project: project, merge_status: :can_be_merged)
    end

    before do
      post_query
    end

    it 'returns null' do
      expect(conflict_files_data).to be_nil
    end
  end

  context 'when the source branch is missing' do
    let_it_be(:merge_request) do
      create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start',
        source_project: project, merge_status: :cannot_be_merged)
    end

    before do
      allow_next_found_instance_of(MergeRequest) do |mr|
        allow(mr).to receive(:branch_missing?).and_return(true)
      end
      post_query
    end

    it 'returns null' do
      expect(conflict_files_data).to be_nil
    end
  end

  context 'when the diff refs are incomplete' do
    let_it_be(:merge_request) do
      create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start',
        source_project: project, merge_status: :cannot_be_merged)
    end

    before do
      allow_next_found_instance_of(MergeRequest) do |mr|
        allow(mr).to receive(:has_complete_diff_refs?).and_return(false)
      end
      post_query
    end

    it 'returns null without attempting to list conflicts' do
      expect(conflict_files_data).to be_nil
    end
  end

  context 'when the conflict involves a binary file' do
    let_it_be(:merge_request) do
      create(:merge_request, source_branch: 'conflict-binary-file', target_branch: 'conflict-start',
        source_project: project, merge_status: :cannot_be_merged)
    end

    before do
      ::MergeRequests::MergeabilityCheckService.new(merge_request).execute
      post_query
    end

    it 'returns null' do
      expect(conflict_files_data).to be_nil
    end
  end

  context 'when a conflict file has unsupported encoding' do
    let_it_be(:merge_request) do
      create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start',
        source_project: project, merge_status: :cannot_be_merged)
    end

    before do
      ::MergeRequests::MergeabilityCheckService.new(merge_request).execute

      allow_next_instance_of(Gitlab::Git::Conflict::File) do |file|
        allow(file).to receive(:content).and_raise(
          Gitlab::Git::Conflict::File::UnsupportedEncoding, 'invalid encoding'
        )
      end
      post_query
    end

    it 'returns null for the content field instead of raising' do
      expect(conflict_files_data).to be_present
      expect(conflict_files_data.first['content']).to be_nil
    end
  end

  context 'when the user cannot read the merge request' do
    let_it_be(:private_project) { create(:project, :private, :repository) }
    let_it_be(:outsider) { create(:user) }
    let_it_be(:private_merge_request) do
      create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start',
        source_project: private_project, merge_status: :cannot_be_merged)
    end

    let(:merge_request) { private_merge_request }
    let(:current_user) { outsider }

    before do
      post_query
    end

    it 'returns null for the merge request itself' do
      expect(graphql_data_at(:merge_request)).to be_nil
    end
  end

  context 'when conflictFiles is requested more than once per query' do
    let_it_be(:merge_request) do
      create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start',
        source_project: project, merge_status: :cannot_be_merged)
    end

    let(:query) do
      <<~GRAPHQL
        query {
          mergeRequest(id: "#{global_id_of(merge_request)}") {
            conflictFiles { ourPath }
            aliasedConflictFiles: conflictFiles { ourPath }
          }
        }
      GRAPHQL
    end

    it 'returns an error for the second call' do
      post_graphql(query, current_user: current_user)

      expect_graphql_errors_to_include(
        '"conflictFiles" field can be requested only for 1 MergeRequest(s) at a time.'
      )
    end
  end
end
