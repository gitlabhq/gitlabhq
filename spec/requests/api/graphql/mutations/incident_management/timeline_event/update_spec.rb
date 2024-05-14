# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating an incident timeline event', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, developers: user) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:tag1) { create(:incident_management_timeline_event_tag, project: project, name: 'Tag 1') }
  let_it_be(:tag2) { create(:incident_management_timeline_event_tag, project: project, name: 'Tag 2') }
  let_it_be_with_reload(:timeline_event) do
    create(:incident_management_timeline_event, incident: incident, project: project)
  end

  # Pre-attach a tag to the event
  let_it_be(:tag_link1) do
    create(:incident_management_timeline_event_tag_link,
      timeline_event: timeline_event,
      timeline_event_tag: tag1
    )
  end

  let(:occurred_at) { 1.minute.ago.iso8601 }
  let(:note) { 'Updated note' }
  let(:tag_names) { [] }

  let(:variables) do
    {
      id: timeline_event.to_global_id.to_s,
      note: note,
      occurred_at: occurred_at,
      timeline_event_tag_names: tag_names
    }
  end

  let(:mutation) do
    graphql_mutation(:timeline_event_update, variables) do
      <<~QL
        clientMutationId
        errors
        timelineEvent {
          id
          author { id username }
          updatedByUser { id username }
          incident { id title }
          timelineEventTags { nodes { name } }
          note
          noteHtml
          occurredAt
          createdAt
          updatedAt
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:timeline_event_update) }

  it 'updates the timeline event', :aggregate_failures do
    post_graphql_mutation(mutation, current_user: user)

    timeline_event_response = mutation_response['timelineEvent']

    timeline_event.reload

    expect(response).to have_gitlab_http_status(:success)
    expect(timeline_event_response).to include(
      'id' => timeline_event.to_global_id.to_s,
      'author' => {
        'id' => timeline_event.author.to_global_id.to_s,
        'username' => timeline_event.author.username
      },
      'updatedByUser' => {
        'id' => user.to_global_id.to_s,
        'username' => user.username
      },
      'incident' => {
        'id' => incident.to_global_id.to_s,
        'title' => incident.title
      },
      'timelineEventTags' => {
        'nodes' => []
      },
      'note' => note,
      'noteHtml' => timeline_event.note_html,
      'occurredAt' => occurred_at,
      'createdAt' => timeline_event.created_at.iso8601,
      'updatedAt' => timeline_event.updated_at.iso8601
    )
  end

  context 'when note is more than 280 characters long' do
    let(:note) { 'n' * 281 }

    it_behaves_like 'timeline event mutation responds with validation error',
      error_message: 'Timeline text is too long (maximum is 280 characters)'
  end

  context 'when timeline event tag names are passed' do
    context 'when tags exist' do
      let(:tag_names) { [tag2.name] }

      it 'removes tag1 and adds tag2' do
        post_graphql_mutation(mutation, current_user: user)

        timeline_event_response = mutation_response['timelineEvent']
        tag_names = timeline_event_response['timelineEventTags']['nodes']

        expect(response).to have_gitlab_http_status(:success)
        expect(tag_names).to contain_exactly({ "name" => tag2.name })
      end
    end

    context 'when tags do not exist' do
      let(:tag_names) { ['some other tag'] }

      it_behaves_like 'timeline event mutation responds with validation error',
        error_message: "Following tags don't exist: [\"some other tag\"]"
    end
  end
end
