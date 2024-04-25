# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating an incident timeline event', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, developers: user) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:event_occurred_at) { Time.current }
  let_it_be(:note) { 'demo note' }
  let_it_be(:tag1) { create(:incident_management_timeline_event_tag, project: project, name: 'Tag 1') }
  let_it_be(:tag2) { create(:incident_management_timeline_event_tag, project: project, name: 'Tag 2') }

  let(:input) do
    { incident_id: incident.to_global_id.to_s,
      note: note,
      occurred_at: event_occurred_at,
      timeline_event_tag_names: [tag1.name] }
  end

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
          timelineEventTags { nodes { name } }
          editable
          action
          occurredAt
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:timeline_event_create) }

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

  context 'when note is more than 280 characters long' do
    let_it_be(:note) { 'n' * 281 }

    it_behaves_like 'timeline event mutation responds with validation error',
      error_message: 'Timeline text is too long (maximum is 280 characters)'
  end

  context 'when timeline event tags are passed' do
    it 'creates incident timeline event with tags', :aggregate_failures do
      post_graphql_mutation(mutation, current_user: user)

      timeline_event_response = mutation_response['timelineEvent']
      tag_names = timeline_event_response['timelineEventTags']['nodes']

      expect(response).to have_gitlab_http_status(:success)
      expect(timeline_event_response).to include(
        'timelineEventTags' => { 'nodes' => tag_names }
      )
    end
  end
end
