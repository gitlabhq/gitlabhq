# frozen_string_literal: true

require 'spec_helper'

describe API::Events do
  let(:user) { create(:user) }
  let(:non_member) { create(:user) }
  let(:private_project) { create(:project, :private, creator_id: user.id, namespace: user.namespace) }
  let(:closed_issue) { create(:closed_issue, project: private_project, author: user) }
  let!(:closed_issue_event) { create(:event, project: private_project, author: user, target: closed_issue, action: Event::CLOSED, created_at: Date.new(2016, 12, 30)) }
  let(:closed_issue2) { create(:closed_issue, project: private_project, author: non_member) }
  let!(:closed_issue_event2) { create(:event, project: private_project, author: non_member, target: closed_issue2, action: Event::CLOSED, created_at: Date.new(2016, 12, 30)) }

  describe 'GET /events' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api('/events')

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'returns users events' do
        get api('/events?action=closed&target_type=issue&after=2016-12-1&before=2016-12-31', user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
      end

      context 'when scope is passed' do
        it 'returns all events across projects' do
          private_project.add_developer(non_member)

          get api('/events?action=closed&target_type=issue&after=2016-12-1&before=2016-12-31&scope=all', user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(2)
        end
      end
    end

    context 'when the requesting token has "read_user" scope' do
      let(:token) { create(:personal_access_token, scopes: ['read_user'], user: user) }

      it 'returns users events' do
        get api('/events?action=closed&target_type=issue&after=2016-12-1&before=2016-12-31', personal_access_token: token)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
      end
    end

    context 'when the requesting token does not have "read_user" or "api" scope' do
      let(:token_without_scopes) { create(:personal_access_token, scopes: ['read_repository'], user: user) }

      it 'returns a "403" response' do
        get api('/events', personal_access_token: token_without_scopes)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'GET /users/:id/events' do
    context "as a user that cannot see another user" do
      it 'returns a "404" response' do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(non_member, :read_user, user).and_return(false)

        get api("/users/#{user.id}/events", non_member)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_empty
      end
    end

    context "as a user token that cannot see another user" do
      let(:non_member_token) { create(:personal_access_token, scopes: ['read_user'], user: non_member) }

      it 'returns a "404" response' do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(non_member, :read_user, user).and_return(false)

        get api("/users/#{user.id}/events", personal_access_token: non_member_token)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_empty
      end
    end

    context "as a user that can see the event's project" do
      it 'accepts a username' do
        get api("/users/#{user.username}/events", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
      end

      it 'returns the events' do
        get api("/users/#{user.id}/events", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
      end

      context 'when the list of events includes push events' do
        let(:event) do
          create(:push_event, author: user, project: private_project)
        end

        let!(:payload) { create(:push_event_payload, event: event) }
        let(:payload_hash) { json_response[0]['push_data'] }

        before do
          get api("/users/#{user.id}/events?action=pushed", user)
        end

        it 'responds with HTTP 200 OK' do
          expect(response).to have_gitlab_http_status(200)
        end

        it 'includes the push payload as a Hash' do
          expect(payload_hash).to be_an_instance_of(Hash)
        end

        it 'includes the push payload details' do
          expect(payload_hash['commit_count']).to eq(payload.commit_count)
          expect(payload_hash['action']).to eq(payload.action)
          expect(payload_hash['ref_type']).to eq(payload.ref_type)
          expect(payload_hash['commit_to']).to eq(payload.commit_to)
          expect(payload_hash['ref_count']).to eq(payload.ref_count)
        end
      end

      context 'when there are multiple events from different projects' do
        let(:second_note) { create(:note_on_issue, project: create(:project)) }

        before do
          second_note.project.add_user(user, :developer)

          [second_note].each do |note|
            EventCreateService.new.leave_note(note, user)
          end
        end

        it 'returns events in the correct order (from newest to oldest)' do
          get api("/users/#{user.id}/events", user)

          comment_events = json_response.select { |e| e['action_name'] == 'commented on' }
          close_events = json_response.select { |e| e['action_name'] == 'closed' }

          expect(comment_events[0]['target_id']).to eq(second_note.id)
          expect(close_events[0]['target_id']).to eq(closed_issue.id)
        end

        it 'accepts filter parameters' do
          get api("/users/#{user.id}/events?action=closed&target_type=issue&after=2016-12-1&before=2016-12-31", user)

          expect(json_response.size).to eq(1)
          expect(json_response[0]['target_id']).to eq(closed_issue.id)
        end
      end
    end

    it 'returns a 404 error if not found' do
      get api('/users/42/events', user)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end
  end
end
