require 'spec_helper'

describe API::Events do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:non_member) { create(:user) }
  let(:other_user) { create(:user, username: 'otheruser') }
  let(:private_project) { create(:empty_project, :private, creator_id: user.id, namespace: user.namespace) }
  let(:closed_issue) { create(:closed_issue, project: private_project, author: user) }
  let!(:closed_issue_event) { create(:event, project: private_project, author: user, target: closed_issue, action: Event::CLOSED, created_at: Date.new(2016, 12, 30)) }

  describe 'GET /events' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api('/events')

        expect(response).to have_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'returns users events' do
        get api('/events?action=closed&target_type=issue&after=2016-12-1&before=2016-12-31', user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
      end
    end
  end

  describe 'GET /users/:id/events' do
    context "as a user that cannot see the event's project" do
      it 'returns no events' do
        get api("/users/#{user.id}/events", other_user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_empty
      end
    end

    context "as a user that can see the event's project" do
      it 'accepts a username' do
        get api("/users/#{user.username}/events", user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
      end

      it 'returns the events' do
        get api("/users/#{user.id}/events", user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
      end

      context 'when there are multiple events from different projects' do
        let(:second_note) { create(:note_on_issue, project: create(:empty_project)) }

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

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end
  end

  describe 'GET /projects/:id/events' do
    context 'when unauthenticated ' do
      it 'returns 404 for private project' do
        get api("/projects/#{private_project.id}/events")

        expect(response).to have_http_status(404)
      end

      it 'returns 200 status for a public project' do
        public_project = create(:empty_project, :public)

        get api("/projects/#{public_project.id}/events")

        expect(response).to have_http_status(200)
      end
    end

    context 'when not permitted to read' do
      it 'returns 404' do
        get api("/projects/#{private_project.id}/events", non_member)

        expect(response).to have_http_status(404)
      end
    end

    context 'when authenticated' do
      it 'returns project events' do
        get api("/projects/#{private_project.id}/events?action=closed&target_type=issue&after=2016-12-1&before=2016-12-31", user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
      end

      it 'returns 404 if project does not exist' do
        get api("/projects/1234/events", user)

        expect(response).to have_http_status(404)
      end
    end
  end
end
