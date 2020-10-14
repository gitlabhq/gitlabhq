# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting milestone listings nested in a project' do
  include GraphqlHelpers

  let_it_be(:today) { Time.now.utc.to_date }
  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:no_dates) { create(:milestone, project: project, title: 'no dates') }
  let_it_be(:no_end) { create(:milestone, project: project, title: 'no end', start_date: today - 10.days) }
  let_it_be(:no_start) { create(:milestone, project: project, title: 'no start', due_date: today - 5.days) }
  let_it_be(:fully_past) { create(:milestone, project: project, title: 'past', start_date: today - 10.days, due_date: today - 5.days) }
  let_it_be(:covers_today) { create(:milestone, project: project, title: 'present', start_date: today - 5.days, due_date: today + 5.days) }
  let_it_be(:fully_future) { create(:milestone, project: project, title: 'future', start_date: today + 5.days, due_date: today + 10.days) }
  let_it_be(:closed) { create(:milestone, :closed, project: project) }

  let(:results) { graphql_data_at(:project, :milestones, :nodes) }

  let(:search_params) { nil }

  def query_milestones(fields)
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_graphql_field(:milestones, search_params, [
        query_graphql_field(:nodes, nil, %i[id title])
      ])
    )
  end

  def result_list(expected)
    expected.map do |milestone|
      a_hash_including('id' => global_id_of(milestone))
    end
  end

  let(:query) do
    query_milestones(all_graphql_fields_for('Milestone', max_depth: 1))
  end

  let(:all_milestones) do
    [no_dates, no_end, no_start, fully_past, fully_future, covers_today, closed]
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  shared_examples 'searching with parameters' do
    it 'finds the right milestones' do
      post_graphql(query, current_user: current_user)

      expect(results).to match_array(result_list(expected))
    end
  end

  context 'there are no search params' do
    let(:search_params) { nil }
    let(:expected) { all_milestones }

    it_behaves_like 'searching with parameters'
  end

  context 'the search params do not match anything' do
    let(:search_params) { { title: 'wibble' } }
    let(:expected) { [] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by state:closed' do
    let(:search_params) { { state: :closed } }
    let(:expected) { [closed] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by state:active' do
    let(:search_params) { { state: :active } }
    let(:expected) { all_milestones - [closed] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by title' do
    let(:search_params) { { title: 'no start' } }
    let(:expected) { [no_start] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by search_title' do
    let(:search_params) { { search_title: 'no' } }
    let(:expected) { [no_dates, no_start, no_end] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by containing_date' do
    let(:search_params) { { containing_date: (today - 7.days).iso8601 } }
    let(:expected) { [no_start, no_end, fully_past] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by containing_date = today' do
    let(:search_params) { { containing_date: today.iso8601 } }
    let(:expected) { [no_end, covers_today] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by custom range' do
    let(:expected) { [no_end, fully_future] }
    let(:search_params) do
      {
        start_date: (today + 6.days).iso8601,
        end_date: (today + 7.days).iso8601
      }
    end

    it_behaves_like 'searching with parameters'
  end

  context 'using timeframe argument' do
    let(:expected) { [no_end, fully_future] }
    let(:search_params) do
      {
        timeframe: {
          start: (today + 6.days).iso8601,
          end: (today + 7.days).iso8601
        }
      }
    end

    it_behaves_like 'searching with parameters'
  end

  describe 'timeframe validations' do
    let(:vars) do
      {
        path: project.full_path,
        start: (today + 6.days).iso8601,
        end: (today + 7.days).iso8601
      }
    end

    it_behaves_like 'a working graphql query' do
      before do
        query = <<~GQL
          query($path: ID!, $start: Date!, $end: Date!) {
            project(fullPath: $path) {
              milestones(timeframe: { start: $start, end: $end }) {
                nodes { id }
              }
            }
          }
        GQL

        post_graphql(query, current_user: current_user, variables: vars)
      end
    end

    it 'is invalid to provide timeframe and start_date/end_date' do
      query = <<~GQL
        query($path: ID!, $tstart: Date!, $tend: Date!, $start: Time!, $end: Time!) {
          project(fullPath: $path) {
            milestones(timeframe: { start: $tstart, end: $tend }, startDate: $start, endDate: $end) {
              nodes { id }
            }
          }
        }
      GQL

      post_graphql(query, current_user: current_user,
                          variables: vars.merge(vars.transform_keys { |k| :"t#{k}" }))

      expect(graphql_errors).to contain_exactly(a_hash_including('message' => include('deprecated in favor of timeframe')))
    end

    it 'is invalid to invert the timeframe arguments' do
      query = <<~GQL
        query($path: ID!, $start: Date!, $end: Date!) {
          project(fullPath: $path) {
            milestones(timeframe: { start: $end, end: $start }) {
              nodes { id }
            }
          }
        }
      GQL

      post_graphql(query, current_user: current_user, variables: vars)

      expect(graphql_errors).to contain_exactly(a_hash_including('message' => include('start must be before end')))
    end
  end
end
