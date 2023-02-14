# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying a Board list', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:board) { create(:board, resource_parent: project) }
  let_it_be(:label) { create(:label, project: project, name: 'foo') }
  let_it_be(:extra_label1) { create(:label, project: project) }
  let_it_be(:extra_label2) { create(:label, project: project) }
  let_it_be(:list) { create(:list, board: board, label: label) }
  let_it_be(:issue1) { create(:issue, project: project, labels: [label, extra_label1]) }
  let_it_be(:issue2) { create(:issue, project: project, labels: [label, extra_label2], assignees: [current_user]) }
  let_it_be(:issue3) { create(:issue, project: project, labels: [label], confidential: true) }

  let(:filters) { {} }
  let(:query) do
    graphql_query_for(
      :board_list,
      { id: list.to_global_id.to_s, issueFilters: filters },
      %w[title issuesCount]
    )
  end

  subject { graphql_data['boardList'] }

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when the user has access to the list' do
    before_all do
      project.add_guest(current_user)
    end

    it_behaves_like 'a working graphql query'

    it { is_expected.to include({ 'issuesCount' => 2, 'title' => list.title }) }

    describe 'issue filters' do
      context 'with matching assignee username issue filters' do
        let(:filters) { { assigneeUsername: current_user.username } }

        it 'filters issues metadata' do
          is_expected.to include({ 'issuesCount' => 1, 'title' => list.title })
        end
      end

      context 'with unmatching assignee username issue filters' do
        let(:filters) { { assigneeUsername: 'foo' } }

        it 'filters issues metadata' do
          is_expected.to include({ 'issuesCount' => 0, 'title' => list.title })
        end
      end

      context 'when filtering by confidential' do
        let(:filters) { { confidential: true } }

        before_all do
          project.add_developer(current_user)
        end

        it 'filters issues metadata' do
          is_expected.to include({ 'issuesCount' => 1, 'title' => list.title })
        end
      end

      context 'when filtering by OR labels' do
        let(:filters) { { or: { labelNames: [extra_label1.title, extra_label2.title] } } }

        before_all do
          project.add_developer(current_user)
        end

        it 'filters issues metadata' do
          is_expected.to include({ 'issuesCount' => 2, 'title' => list.title })
        end
      end
    end
  end

  context 'when the user does not have access to the list' do
    it { is_expected.to be_nil }
  end

  context 'when ID argument is missing' do
    let(:query) do
      graphql_query_for('boardList', {}, 'title')
    end

    it 'raises an exception' do
      expect(graphql_errors).to include(a_hash_including('message' => "Field 'boardList' is missing required arguments: id"))
    end
  end

  context 'when list ID is not found' do
    let(:query) do
      graphql_query_for('boardList', { id: "gid://gitlab/List/#{non_existing_record_id}" }, 'title')
    end

    it { is_expected.to be_nil }
  end

  it 'does not have an N+1 performance issue' do
    a, b = create_list(:list, 2, board: board)
    ctx = { current_user: current_user }
    project.add_guest(current_user)

    baseline = graphql_query_for(:board_list, { id: global_id_of(a) }, 'title')
    query = <<~GQL
      query {
        a: #{query_graphql_field(:board_list, { id: global_id_of(a) }, 'title')}
        b: #{query_graphql_field(:board_list, { id: global_id_of(b) }, 'title')}
      }
    GQL

    control = ActiveRecord::QueryRecorder.new do
      run_with_clean_state(baseline, context: ctx)
    end

    expect { run_with_clean_state(query, context: ctx) }.not_to exceed_query_limit(control)
  end
end
