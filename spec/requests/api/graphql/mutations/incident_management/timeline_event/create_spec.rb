# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating an incident timeline event' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:event_occurred_at) { Time.current }
  let_it_be(:note) { 'demo note' }

  let(:input) { { incident_id: incident.to_global_id.to_s, note: note, occurred_at: event_occurred_at } }
  let(:mutation) do
    graphql_mutation(:timeline_event_create, input) do
      <<~QL
        clientMutationId
        errors
        timelineEvent {
          id
          author { id username }
          incident { id title }
          note
          editable
          action
          occurredAt
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:timeline_event_create) }

  before do
    project.add_developer(user)
  end

  it 'creates incident timeline event', :aggregate_failures do
    post_graphql_mutation(mutation, current_user: user)

    timeline_event_response = mutation_response['timelineEvent']

    expect(response).to have_gitlab_http_status(:success)
    expect(timeline_event_response).to include(
      'author' => {
        'id' => user.to_global_id.to_s,
        'username' => user.username
      },
      'incident' => {
        'id' => incident.to_global_id.to_s,
        'title' => incident.title
      },
      'note' => note,
      'action' => 'comment',
      'editable' => true,
      'occurredAt' => event_occurred_at.iso8601
    )
  end
end
