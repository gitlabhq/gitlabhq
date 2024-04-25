# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting Alert Management Alert Notes', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:first_alert) { create(:alert_management_alert, project: project, assignees: [current_user]) }
  let_it_be(:second_alert) { create(:alert_management_alert, project: project) }
  let_it_be(:first_system_note) { create(:note_on_alert, :with_system_note_metadata, noteable: first_alert, project: project) }
  let_it_be(:second_system_note) { create(:note_on_alert, :with_system_note_metadata, noteable: first_alert, project: project) }

  let(:params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        iid
        notes {
          nodes {
            id
            body
            systemNoteIconName
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
  let(:notes_result) { alerts_result.to_h { |alert| [alert['iid'], alert['notes']['nodes']] } }
  let(:first_notes_result) { notes_result[first_alert.iid.to_s] }
  let(:second_notes_result) { notes_result[second_alert.iid.to_s] }

  it 'includes expected data' do
    post_graphql(query, current_user: current_user)

    expect(first_notes_result.first).to include(
      'id' => first_system_note.to_global_id.to_s,
      'systemNoteIconName' => 'merge',
      'body' => first_system_note.note
    )
  end

  it 'returns the notes ordered by createdAt with sufficient content' do
    post_graphql(query, current_user: current_user)

    expect(first_notes_result.length).to eq(2)
    expect(first_notes_result.first).to include('id' => first_system_note.to_global_id.to_s)
    expect(first_notes_result.second).to include('id' => second_system_note.to_global_id.to_s)
    expect(second_notes_result).to be_empty
  end

  describe 'performance' do
    let(:first_n) { var('Int') }
    let(:params) { { first: first_n } }

    before do
      # An N+1 would mean a new alert would increase the query count
      create(:alert_management_alert, project: project)
    end

    it 'avoids N+1 queries' do
      q = with_signature([first_n], query)

      base_count = ActiveRecord::QueryRecorder.new do
        post_graphql(q, current_user: current_user, variables: first_n.with(1))
        expect(alerts_result.length).to eq(1)
      end

      expect do
        post_graphql(q, current_user: current_user, variables: first_n.with(3))
        expect(alerts_result.length).to eq(3)
      end.not_to exceed_query_limit(base_count)
    end
  end

  context 'for non-system notes' do
    let_it_be(:user_note) { create(:note_on_alert, noteable: second_alert, project: project) }

    it 'includes expected data' do
      post_graphql(query, current_user: current_user)

      expect(second_notes_result.first).to include(
        'id' => user_note.to_global_id.to_s,
        'systemNoteIconName' => nil,
        'body' => user_note.note
      )
    end
  end
end
