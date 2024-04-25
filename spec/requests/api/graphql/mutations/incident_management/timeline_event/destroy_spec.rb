# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Removing an incident timeline event', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, developers: user) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:timeline_event) { create(:incident_management_timeline_event, incident: incident, project: project) }

  let(:variables) { { id: timeline_event.to_global_id.to_s } }

  let(:mutation) do
    graphql_mutation(:timeline_event_destroy, variables) do
      <<~QL
        clientMutationId
        errors
        timelineEvent {
          id
          author { id username }
          incident { id title }
          note
          noteHtml
          editable
          action
          occurredAt
          createdAt
          updatedAt
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:timeline_event_destroy) }

  it 'removes incident timeline event', :aggregate_failures do
    post_graphql_mutation(mutation, current_user: user)

    timeline_event_response = mutation_response['timelineEvent']

    expect(response).to have_gitlab_http_status(:success)
    expect(timeline_event_response).to include(
      'author' => {
        'id' => timeline_event.author.to_global_id.to_s,
        'username' => timeline_event.author.username
      },
      'incident' => {
        'id' => incident.to_global_id.to_s,
        'title' => incident.title
      },
      'note' => timeline_event.note,
      'noteHtml' => timeline_event.note_html,
      'editable' => true,
      'action' => timeline_event.action,
      'occurredAt' => timeline_event.occurred_at.iso8601,
      'createdAt' => timeline_event.created_at.iso8601,
      'updatedAt' => timeline_event.updated_at.iso8601
    )
    expect { timeline_event.reload }.to raise_error ActiveRecord::RecordNotFound
  end
end
