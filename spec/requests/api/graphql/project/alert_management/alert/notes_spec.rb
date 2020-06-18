# frozen_string_literal: true

require 'spec_helper'

describe 'getting Alert Management Alert Notes' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:first_alert) { create(:alert_management_alert, project: project, assignees: [current_user]) }
  let_it_be(:second_alert) { create(:alert_management_alert, project: project) }
  let_it_be(:first_system_note) { create(:note_on_alert, noteable: first_alert, project: project) }
  let_it_be(:second_system_note) { create(:note_on_alert, noteable: first_alert, project: project) }

  let(:params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        iid
        notes {
          nodes {
            id
          }
        }
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('alertManagementAlerts', params, fields)
    )
  end

  let(:alerts_result) { graphql_data.dig('project', 'alertManagementAlerts', 'nodes') }
  let(:notes_result) { alerts_result.map { |alert| [alert['iid'], alert['notes']['nodes']] }.to_h }
  let(:first_notes_result) { notes_result[first_alert.iid.to_s] }
  let(:second_notes_result) { notes_result[second_alert.iid.to_s] }

  before do
    project.add_developer(current_user)
  end

  it 'returns the notes ordered by createdAt' do
    post_graphql(query, current_user: current_user)

    expect(first_notes_result.length).to eq(2)
    expect(first_notes_result.first).to include('id' => first_system_note.to_global_id.to_s)
    expect(first_notes_result.second).to include('id' => second_system_note.to_global_id.to_s)
    expect(second_notes_result).to be_empty
  end

  it 'avoids N+1 queries' do
    base_count = ActiveRecord::QueryRecorder.new do
      post_graphql(query, current_user: current_user)
    end

    # An N+1 would mean a new alert would increase the query count
    create(:alert_management_alert, project: project)

    expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(base_count)
    expect(alerts_result.length).to eq(3)
  end
end
