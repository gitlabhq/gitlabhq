# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'getting Issue counts by status', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:issue_opened) { create(:issue, project: project) }
  let_it_be(:issue_closed) { create(:issue, :closed, project: project) }
  let_it_be(:other_project_issue) { create(:issue) }

  let(:params) { {} }

  let(:fields) do
    <<~QUERY
      #{all_graphql_fields_for('IssueStatusCountsType'.classify)}
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('issueStatusCounts', params, fields)
    )
  end

  context 'with issue count data' do
    let(:issue_counts) { graphql_data.dig('project', 'issueStatusCounts') }

    context 'without project permissions' do
      let(:user) { create(:user) }

      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'
      it { expect(issue_counts).to be_nil }
    end

    context 'with project permissions' do
      before do
        project.add_developer(current_user)
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'
      it 'returns the correct counts for each status' do
        expect(issue_counts).to eq(
          'all' => 2,
          'opened' => 1,
          'closed' => 1
        )
      end

      context 'when filtering by assignees' do
        let_it_be(:some_issue) { create(:issue, project: project, assignees: [create(:user, username: "greatuser")]) }

        context 'when assignee is provided' do
          let(:params) { { 'assigneeUsernames' => ["greatuser"] } }

          it 'returns the correct counts for each status' do
            expect(issue_counts).to eq(
              'all' => 1,
              'opened' => 1,
              'closed' => 0
            )
          end
        end

        context 'when nil assignee is provided' do
          let(:params) { { 'assigneeUsernames' => nil } }

          it 'returns the correct counts for each status and does not error' do
            expect(issue_counts).to eq(
              'all' => 3,
              'opened' => 2,
              'closed' => 1
            )
          end
        end
      end
    end
  end
end
