# frozen_string_literal: true

RSpec.shared_examples 'value stream related stage items query' do |group_or_project|
  let(:resource_path) { group_or_project.to_sym }

  let_it_be(:user) { create(:user) }

  let_it_be(:current_time) do
    Time.zone.parse('2024-07-15')
  end

  let(:query) do
    <<~GQL
      query($fullPath: ID!, $from: Date!, $to: Date!, $authorUsername: String) {
        #{resource_path}(fullPath: $fullPath) {
          id
          valueStreams {
            #{fields}
          }
        }
      }
    GQL
  end

  let(:fields) do
    <<~GRAPHQL
      nodes {
        stages {
          name
          metrics(timeframe: { start: $from, end: $to }, authorUsername: $authorUsername) {
            items {
              nodes {
                endEventTimestamp
                duration

                record {
                  ... on MergeRequest {
                    id
                  }
                  ... on Issue {
                    id
                  }
                }
              }
            }
          }
        }
      }
    GRAPHQL
  end

  let_it_be(:merge_request1) do
    create(:merge_request, :unique_branches, source_project: project, created_at: current_time - 1.day).tap do |mr|
      mr.metrics.update!(latest_build_started_at: current_time - 10.hours,
        latest_build_finished_at: current_time - 3.hours)
    end
  end

  let_it_be(:merge_request2) do
    create(:merge_request, :unique_branches, source_project: project, created_at: current_time - 1.day).tap do |mr|
      mr.metrics.update!(latest_build_started_at: current_time - 12.hours,
        latest_build_finished_at: current_time - 4.hours)
    end
  end

  let_it_be(:issue1) do
    create(:issue, project: project, created_at: current_time - 4.days).tap do |i|
      i.metrics.update!(first_associated_with_milestone_at: current_time - 2.days)
    end
  end

  let_it_be(:issue2) do
    create(:issue, project: project, created_at: current_time - 1.hour).tap do |i|
      i.metrics.update!(first_associated_with_milestone_at: current_time - 30.minutes)
    end
  end

  let(:variables) do
    {
      fullPath: resource.full_path,
      from: "2024-07-01",
      to: "2024-08-01"
    }
  end

  before_all do
    resource.add_developer(user)
  end

  before do
    travel_to(current_time)
  end

  it 'returns stage related merge requests data' do
    post_graphql(query, current_user: user, variables: variables)
    data = get_stage_data_by(name: 'test')

    expect(data.size).to eq(2)
    expect(data).to include({
      'endEventTimestamp' => '2024-07-14T21:00:00Z',
      'duration' => '7 hours',
      'record' => { 'id' => merge_request1.to_global_id.to_s }
    })

    expect(data).to include({
      'endEventTimestamp' => '2024-07-14T20:00:00Z',
      'duration' => '8 hours',
      'record' => { 'id' => merge_request2.to_global_id.to_s }
    })
  end

  it 'returns stage related issues data' do
    post_graphql(query, current_user: user, variables: variables)
    data = get_stage_data_by(name: 'issue')

    expect(data.size).to eq(2)
    expect(data).to include({
      'endEventTimestamp' => '2024-07-13T00:00:00Z',
      'duration' => '2 days',
      'record' => { 'id' => issue1.to_global_id.to_s }
    })

    expect(data).to include({
      'endEventTimestamp' => '2024-07-14T23:30:00Z',
      'duration' => '30 mins',
      'record' => { 'id' => issue2.to_global_id.to_s }
    })
  end

  context 'when using pagination' do
    def pagination_query(params)
      fields =
        <<~GRAPHQL
        record {
          ... on MergeRequest {
            id
          }
        }
        GRAPHQL

      graphql_query_for(resource_path, { full_path: resource.full_path },
        <<~QUERY
        valueStreams(first: 1) {
          nodes {
            stages(id: "#{stage_id_to_paginate}") {
              metrics(timeframe: { start: "2024-07-01", end: "2024-08-01" }) {
                #{query_nodes(:items, fields, include_pagination_info: true, args: params)}
              }
            }
          }
        }
        QUERY
      )
    end

    it_behaves_like 'sorted paginated query' do
      let(:sort_param) { :END_EVENT_ASC }

      let(:current_user) { user }
      let(:data_path) { [resource_path, :valueStreams, :nodes, 0, :stages, :metrics, :items] }
      let(:node_path) { %w[record id] }
      let(:first_param) { 1 }
      let(:all_records) { [merge_request2, merge_request1].map(&:to_global_id).map(&:to_s) }
    end
  end

  def get_stage_data_by(name:)
    data = graphql_data_at(resource_path, :value_streams, :nodes, 0, :stages)

    stage_data =
      data.find { |node| node['name'].downcase == name }

    stage_data.dig('metrics', 'items', 'nodes')
  end
end
