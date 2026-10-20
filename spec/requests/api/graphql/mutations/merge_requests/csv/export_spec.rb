# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Export merge requests', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  let(:input) { { 'projectPath' => project.full_path } }
  let(:mutation) { graphql_mutation(:merge_requests_csv_export, input) }
  let(:mutation_response) { graphql_mutation_response(:merge_requests_csv_export) }

  context 'when user can read merge requests' do
    let(:current_user) { developer }
    let(:input) do
      super().merge(
        'state' => 'merged',
        'mergedBy' => 'cleveland',
        'targetBranches' => ['main'],
        'assigneeUsernames' => ['maintainer'],
        'not' => { 'sourceBranches' => ['feature'] },
        'search' => 'fix',
        'in' => 'TITLE'
      )
    end

    it 'schedules the export with finder parameter names', :aggregate_failures do
      expected_arguments = {
        state: 'merged',
        merge_user_username: 'cleveland',
        target_branch: ['main'],
        assignee_username: ['maintainer'],
        not: { source_branch: ['feature'] },
        search: 'fix',
        in: 'title',
        attempt_project_search_optimizations: true
      }

      expect(IssuableExportCsvWorker)
        .to receive(:perform_async).with(:merge_request, current_user.id, project.id, expected_arguments)

      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['message']).to eq(
        'Your CSV export request has succeeded. The result will be emailed to ' \
          "#{developer.notification_email_or_default}."
      )
      expect(mutation_response['errors']).to be_empty
    end

    context 'when closedAfter is given without closedBefore' do
      let(:input) { { 'projectPath' => project.full_path, 'closedAfter' => 1.day.ago.iso8601 } }

      it 'returns an error and does not schedule the export' do
        expect(IssuableExportCsvWorker).not_to receive(:perform_async)

        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).to include(
          a_hash_including('message' => 'You must provide both closedAfter and closedBefore.')
        )
      end
    end

    it_behaves_like 'authorizing granular token permissions for GraphQL', :read_merge_request do
      let(:user) { current_user }
      let(:boundary_object) { project }
      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end
  end

  describe 'search' do
    let_it_be(:public_project) { create(:project, :public, :repository, developers: developer) }
    let_it_be(:ui_merge_request) do
      create(:merge_request, source_project: public_project, source_branch: 'feature_conflict',
        target_branch: 'master', title: 'Fix UI bug')
    end

    let_it_be(:backend_merge_request) do
      create(:merge_request, source_project: public_project, source_branch: 'markdown',
        target_branch: 'master', title: 'Refactor backend')
    end

    def list_iids(search)
      query = graphql_query_for(:project, { full_path: public_project.full_path },
        query_graphql_field(:merge_requests, { search: search }, 'nodes { iid }'))
      post_graphql(query, current_user: developer)
      graphql_data_at(:project, :merge_requests, :nodes).map { |node| node['iid'] }.sort
    end

    def export_iids(search)
      exported = nil
      allow(MergeRequests::ExportCsvService).to receive(:new).and_wrap_original do |method, issuables, *rest|
        exported = issuables.map { |merge_request| merge_request.iid.to_s }.sort
        method.call(issuables, *rest)
      end

      Sidekiq::Testing.inline! do
        input = { 'projectPath' => public_project.full_path, 'search' => search }
        post_graphql_mutation(graphql_mutation(:merge_requests_csv_export, input), current_user: developer)
      end

      exported
    end

    where(:term) { ['UI', 'fix ab', 'Refactor'] }

    with_them do
      it 'exports the same merge requests as the list' do
        expect(export_iids(term)).to eq(list_iids(term))
      end
    end
  end

  context 'when user cannot read merge requests' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not schedule the export' do
      expect(IssuableExportCsvWorker).not_to receive(:perform_async)

      post_graphql_mutation(mutation, current_user: current_user)
    end
  end

  context 'when the user is anonymous on a public project' do
    let_it_be(:public_project) { create(:project, :public) }

    let(:current_user) { nil }
    let(:input) { { 'projectPath' => public_project.full_path } }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not schedule the export' do
      expect(IssuableExportCsvWorker).not_to receive(:perform_async)

      post_graphql_mutation(mutation, current_user: current_user)
    end
  end
end
