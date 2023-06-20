# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting incident timeline events', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:private_project) { create(:project, :private) }
  let_it_be(:issue) { create(:issue, project: private_project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:updated_by_user) { create(:user) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:another_incident) { create(:incident, project: project) }
  let_it_be(:promoted_from_note) { create(:note, project: project, noteable: incident) }
  let_it_be(:issue_url) { project_issue_url(private_project, issue) }
  let_it_be(:issue_ref) { "#{private_project.full_path}##{issue.iid}" }
  let_it_be(:issue_link) { %(<a href="#{issue_url}">#{issue_url}</a>) }

  let_it_be(:timeline_event) do
    create(
      :incident_management_timeline_event,
      incident: incident,
      project: project,
      updated_by_user: updated_by_user,
      promoted_from_note: promoted_from_note,
      note: "Referencing #{issue.to_reference(full: true)} - Full URL #{issue_url}"
    )
  end

  let_it_be(:second_timeline_event) do
    create(:incident_management_timeline_event, incident: incident, project: project)
  end

  let_it_be(:another_timeline_event) do
    create(:incident_management_timeline_event, incident: another_incident, project: project)
  end

  let(:params) { { incident_id: incident.to_global_id.to_s } }

  let(:timeline_event_fields) do
    <<~QUERY
      nodes {
        id
        author { id username }
        updatedByUser { id username }
        incident { id title }
        note
        noteHtml
        promotedFromNote { id body }
        timelineEventTags { nodes { name } }
        editable
        action
        occurredAt
        createdAt
        updatedAt
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('incidentManagementTimelineEvents', params, timeline_event_fields)
    )
  end

  let(:timeline_events) do
    graphql_data.dig('project', 'incidentManagementTimelineEvents', 'nodes')
  end

  before do
    project.add_guest(current_user)
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query'

  it 'returns the correct number of timeline events' do
    expect(timeline_events.count).to eq(2)
  end

  it 'returns the correct properties of the incident timeline events' do
    expect(timeline_events.first).to include(
      'author' => {
        'id' => timeline_event.author.to_global_id.to_s,
        'username' => timeline_event.author.username
      },
      'updatedByUser' => {
        'id' => updated_by_user.to_global_id.to_s,
        'username' => updated_by_user.username
      },
      'incident' => {
        'id' => incident.to_global_id.to_s,
        'title' => incident.title
      },
      'note' => timeline_event.note,
      'noteHtml' => "<p>Referencing #{issue_ref} - Full URL #{issue_link}</p>",
      'promotedFromNote' => {
        'id' => promoted_from_note.to_global_id.to_s,
        'body' => promoted_from_note.note
      },
      'timelineEventTags' => { 'nodes' => [] },
      'editable' => true,
      'action' => timeline_event.action,
      'occurredAt' => timeline_event.occurred_at.iso8601,
      'createdAt' => timeline_event.created_at.iso8601,
      'updatedAt' => timeline_event.updated_at.iso8601
    )
  end

  context 'when timelineEvent tags are linked' do
    let_it_be(:tag1) { create(:incident_management_timeline_event_tag, project: project, name: 'Tag 1') }
    let_it_be(:tag2) { create(:incident_management_timeline_event_tag, project: project, name: 'Tag 2') }
    let_it_be(:timeline_event_tag_link) do
      create(:incident_management_timeline_event_tag_link,
        timeline_event: timeline_event,
        timeline_event_tag: tag1)
    end

    it_behaves_like 'a working graphql query'

    it 'returns the set tags' do
      expect(timeline_events.first['timelineEventTags']['nodes'].first['name']).to eq(tag1.name)
    end

    context 'when different timeline events are loaded' do
      it 'avoids N+1 queries' do
        control = ActiveRecord::QueryRecorder.new do
          post_graphql(query, current_user: current_user)
        end

        new_event = create(:incident_management_timeline_event,
          incident: incident,
          project: project,
          updated_by_user: updated_by_user,
          promoted_from_note: promoted_from_note,
          note: "Referencing #{issue.to_reference(full: true)} - Full URL #{issue_url}"
        )

        create(:incident_management_timeline_event_tag_link,
          timeline_event: new_event,
          timeline_event_tag: tag2
        )

        expect(incident.incident_management_timeline_events.length).to eq(3)
        expect(post_graphql(query, current_user: current_user)).not_to exceed_query_limit(control)
        expect(timeline_events.count).to eq(3)
      end
    end
  end

  context 'when filtering by id' do
    let(:params) { { incident_id: incident.to_global_id.to_s, id: timeline_event.to_global_id.to_s } }

    let(:query) do
      graphql_query_for(
        'project',
        { 'fullPath' => project.full_path },
        query_graphql_field('incidentManagementTimelineEvent', params, 'id occurredAt')
      )
    end

    it_behaves_like 'a working graphql query'

    it 'returns a single timeline event', :aggregate_failures do
      single_timeline_event = graphql_data.dig('project', 'incidentManagementTimelineEvent')

      expect(single_timeline_event).to include(
        'id' => timeline_event.to_global_id.to_s,
        'occurredAt' => timeline_event.occurred_at.iso8601
      )
    end
  end
end
