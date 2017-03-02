require 'spec_helper'

describe API::V3::Users, api: true  do
  include ApiHelpers

  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }
  let(:key)   { create(:key, user: user) }
  let(:email)   { create(:email, user: user) }
  let(:ldap_blocked_user) { create(:omniauth_user, provider: 'ldapmain', state: 'ldap_blocked') }

  describe 'GET /user/:id/keys' do
    before { admin }

    context 'when unauthenticated' do
      it 'returns authentication error' do
        get v3_api("/users/#{user.id}/keys")
        expect(response).to have_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'returns 404 for non-existing user' do
        get v3_api('/users/999999/keys', admin)
        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns array of ssh keys' do
        user.keys << key
        user.save

        get v3_api("/users/#{user.id}/keys", admin)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['title']).to eq(key.title)
      end
    end
  end

  describe 'GET /user/:id/emails' do
    before { admin }

    context 'when unauthenticated' do
      it 'returns authentication error' do
        get v3_api("/users/#{user.id}/emails")
        expect(response).to have_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'returns 404 for non-existing user' do
        get v3_api('/users/999999/emails', admin)
        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns array of emails' do
        user.emails << email
        user.save

        get v3_api("/users/#{user.id}/emails", admin)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['email']).to eq(email.email)
      end

      it "returns a 404 for invalid ID" do
        put v3_api("/users/ASDF/emails", admin)

        expect(response).to have_http_status(404)
      end
    end
  end

  describe "GET /user/keys" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get v3_api("/user/keys")
        expect(response).to have_http_status(401)
      end
    end

    context "when authenticated" do
      it "returns array of ssh keys" do
        user.keys << key
        user.save

        get v3_api("/user/keys", user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first["title"]).to eq(key.title)
      end
    end
  end

  describe "GET /user/emails" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get v3_api("/user/emails")
        expect(response).to have_http_status(401)
      end
    end

    context "when authenticated" do
      it "returns array of emails" do
        user.emails << email
        user.save

        get v3_api("/user/emails", user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first["email"]).to eq(email.email)
      end
    end
  end

  describe 'PUT /users/:id/block' do
    before { admin }
    it 'blocks existing user' do
      put v3_api("/users/#{user.id}/block", admin)
      expect(response).to have_http_status(200)
      expect(user.reload.state).to eq('blocked')
    end

    it 'does not re-block ldap blocked users' do
      put v3_api("/users/#{ldap_blocked_user.id}/block", admin)
      expect(response).to have_http_status(403)
      expect(ldap_blocked_user.reload.state).to eq('ldap_blocked')
    end

    it 'does not be available for non admin users' do
      put v3_api("/users/#{user.id}/block", user)
      expect(response).to have_http_status(403)
      expect(user.reload.state).to eq('active')
    end

    it 'returns a 404 error if user id not found' do
      put v3_api('/users/9999/block', admin)
      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end
  end

  describe 'PUT /users/:id/unblock' do
    let(:blocked_user)  { create(:user, state: 'blocked') }
    before { admin }

    it 'unblocks existing user' do
      put v3_api("/users/#{user.id}/unblock", admin)
      expect(response).to have_http_status(200)
      expect(user.reload.state).to eq('active')
    end

    it 'unblocks a blocked user' do
      put v3_api("/users/#{blocked_user.id}/unblock", admin)
      expect(response).to have_http_status(200)
      expect(blocked_user.reload.state).to eq('active')
    end

    it 'does not unblock ldap blocked users' do
      put v3_api("/users/#{ldap_blocked_user.id}/unblock", admin)
      expect(response).to have_http_status(403)
      expect(ldap_blocked_user.reload.state).to eq('ldap_blocked')
    end

    it 'does not be available for non admin users' do
      put v3_api("/users/#{user.id}/unblock", user)
      expect(response).to have_http_status(403)
      expect(user.reload.state).to eq('active')
    end

    it 'returns a 404 error if user id not found' do
      put v3_api('/users/9999/block', admin)
      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 for invalid ID" do
      put v3_api("/users/ASDF/block", admin)

      expect(response).to have_http_status(404)
    end
  end

  describe 'GET /users/:id/events' do
    let(:user) { create(:user) }
    let(:project) { create(:empty_project) }
    let(:note) { create(:note_on_issue, note: 'What an awesome day!', project: project) }

    before do
      project.add_user(user, :developer)
      EventCreateService.new.leave_note(note, user)
    end

    context "as a user than cannot see the event's project" do
      it 'returns no events' do
        other_user = create(:user)

        get api("/users/#{user.id}/events", other_user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_empty
      end
    end

    context "as a user than can see the event's project" do
      context 'joined event' do
        it 'returns the "joined" event' do
          get v3_api("/users/#{user.id}/events", user)

          expect(response).to have_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array

          comment_event = json_response.find { |e| e['action_name'] == 'commented on' }

          expect(comment_event['project_id'].to_i).to eq(project.id)
          expect(comment_event['author_username']).to eq(user.username)
          expect(comment_event['note']['id']).to eq(note.id)
          expect(comment_event['note']['body']).to eq('What an awesome day!')

          joined_event = json_response.find { |e| e['action_name'] == 'joined' }

          expect(joined_event['project_id'].to_i).to eq(project.id)
          expect(joined_event['author_username']).to eq(user.username)
          expect(joined_event['author']['name']).to eq(user.name)
        end
      end

      context 'when there are multiple events from different projects' do
        let(:second_note) { create(:note_on_issue, project: create(:empty_project)) }
        let(:third_note) { create(:note_on_issue, project: project) }

        before do
          second_note.project.add_user(user, :developer)

          [second_note, third_note].each do |note|
            EventCreateService.new.leave_note(note, user)
          end
        end

        it 'returns events in the correct order (from newest to oldest)' do
          get v3_api("/users/#{user.id}/events", user)

          comment_events = json_response.select { |e| e['action_name'] == 'commented on' }

          expect(comment_events[0]['target_id']).to eq(third_note.id)
          expect(comment_events[1]['target_id']).to eq(second_note.id)
          expect(comment_events[2]['target_id']).to eq(note.id)
        end
      end
    end

    it 'returns a 404 error if not found' do
      get v3_api('/users/42/events', user)

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end
  end
end
