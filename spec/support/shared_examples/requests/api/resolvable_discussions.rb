shared_examples 'resolvable discussions API' do |parent_type, noteable_type, id_name|
  describe "PUT /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions/:discussion_id" do
    it "resolves discussion if resolved is true" do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}", user), resolved: true

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['notes'].size).to eq(1)
      expect(json_response['notes'][0]['resolved']).to eq(true)
    end

    it "unresolves discussion if resolved is false" do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}", user), resolved: false

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['notes'].size).to eq(1)
      expect(json_response['notes'][0]['resolved']).to eq(false)
    end

    it "returns a 400 bad request error if resolved parameter is not passed" do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}", user)

      expect(response).to have_gitlab_http_status(400)
    end

    it "returns a 401 unauthorized error if user is not authenticated" do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}"), resolved: true

      expect(response).to have_gitlab_http_status(401)
    end

    it "returns a 403 error if user resolves discussion of someone else" do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}", private_user), resolved: true

      expect(response).to have_gitlab_http_status(403)
    end

    context 'when user does not have access to read the discussion' do
      before do
        parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'responds with 404' do
        put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
                "discussions/#{note.discussion_id}", private_user), resolved: true

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe "PUT /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions/:discussion_id/notes/:note_id" do
    it 'returns resolved note when resolved parameter is true' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}/notes/#{note.id}", user), resolved: true

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['resolved']).to eq(true)
    end

    it 'returns a 404 error when note id not found' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}/notes/12345", user),
              body: 'Hello!'

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns a 400 bad request error if neither body nor resolved parameter is given' do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}/notes/#{note.id}", user)

      expect(response).to have_gitlab_http_status(400)
    end

    it "returns a 403 error if user resolves note of someone else" do
      put api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
              "discussions/#{note.discussion_id}/notes/#{note.id}", private_user), resolved: true

      expect(response).to have_gitlab_http_status(403)
    end
  end
end
