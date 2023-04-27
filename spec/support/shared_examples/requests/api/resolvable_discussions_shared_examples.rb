# frozen_string_literal: true

RSpec.shared_examples 'resolvable discussions API' do |parent_type, noteable_type, id_name|
  describe "PUT /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions/:discussion_id" do
    it "resolves discussion if resolved is true" do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}", user), params: { resolved: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['notes'].size).to eq(1)
      expect(json_response['notes'][0]['resolved']).to eq(true)
      expect(Time.parse(json_response['notes'][0]['resolved_at'])).to be_like_time(note.reload.resolved_at)
    end

    it "unresolves discussion if resolved is false" do
      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
        .to receive(:track_unresolve_thread_action).with(user: user)

      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}", user), params: { resolved: false }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['notes'].size).to eq(1)
      expect(json_response['notes'][0]['resolved']).to eq(false)
      expect(json_response['notes'][0]['resolved_at']).to be_nil
    end

    it "returns a 400 bad request error if resolved parameter is not passed" do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}", user)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "returns a 401 unauthorized error if user is not authenticated" do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}"), params: { resolved: true }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it "returns a 403 error if user resolves discussion of someone else" do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}", private_user), params: { resolved: true }

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'when user does not have access to read the discussion' do
      before do
        parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'responds with 404' do
        put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                "discussions/#{note.discussion_id}", private_user), params: { resolved: true }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "PUT /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions/:discussion_id/notes/:note_id" do
    it 'returns resolved note when resolved parameter is true' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}/notes/#{note.id}", user), params: { resolved: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['resolved']).to eq(true)
    end

    it 'returns a 404 error when note id not found' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}/notes/#{non_existing_record_id}", user), params: { body: 'Hello!' }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns a 400 bad request error if neither body nor resolved parameter is given' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}/notes/#{note.id}", user)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "returns a 403 error if user resolves note of someone else" do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}/notes/#{note.id}", private_user), params: { resolved: true }

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end
